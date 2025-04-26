import 'package:flutter/material.dart';
import '../Servers/admin_api.dart';
import 'package:intl/intl.dart';

import 'admin_donations_screen.dart';

class BloodBankInventoryScreen extends StatefulWidget {
  const BloodBankInventoryScreen({Key? key}) : super(key: key);

  @override
  State<BloodBankInventoryScreen> createState() => _BloodBankInventoryScreenState();
}

class _BloodBankInventoryScreenState extends State<BloodBankInventoryScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _bloodInventory = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  // List of all possible blood groups
  final List<String> _allBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inventory = await _adminApiService.getBloodInventory();
      final requests = await _adminApiService.getPendingBloodRequests();

      setState(() {
        _bloodInventory = List<Map<String, dynamic>>.from(inventory);
        _pendingRequests = List<Map<String, dynamic>>.from(requests);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _showUpdateInventoryDialog() {
    final _formKey = GlobalKey<FormState>();

    // Get available blood groups in inventory
    List<String> availableGroups = _bloodInventory
        .map<String>((item) => item['blood_group'] as String)
        .toList();

    // Remove duplicates and ensure we have all blood groups
    Set<String> uniqueGroups = Set<String>.from(availableGroups);
    if (uniqueGroups.isEmpty) {
      uniqueGroups = Set<String>.from(_allBloodGroups);
    } else {
      uniqueGroups.addAll(_allBloodGroups);
    }

    List<String> bloodGroupOptions = uniqueGroups.toList()..sort();

    // Make sure selectedBloodGroup is in the options
    String selectedBloodGroup = bloodGroupOptions.isNotEmpty ? bloodGroupOptions[0] : 'A+';
    int unitsToAdd = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Blood Inventory'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: bloodGroupOptions.map((String group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedBloodGroup = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Units to Add',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter units';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                onSaved: (value) {
                  unitsToAdd = int.parse(value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                Navigator.pop(context);
                _updateInventory(selectedBloodGroup, unitsToAdd);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInventory(String bloodGroup, int units) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminApiService.updateBloodInventory(
        bloodGroup: bloodGroup,
        units: units,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventory updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update inventory'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating inventory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fulfillRequest(String requestId, String bloodGroup, int units) async {
    // Check if we have enough inventory
    final inventoryItem = _bloodInventory.firstWhere(
          (item) => item['blood_group'] == bloodGroup,
      orElse: () => {'units': 0},
    );

    if ((inventoryItem['units'] ?? 0) < units) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough $bloodGroup units in inventory'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminApiService.fulfillBloodRequest(
        requestId: requestId,
        bloodGroup: bloodGroup,
        units: units,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request fulfilled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fulfill request'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fulfilling request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Blood Bank Inventory',
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInventorySection(),
              SizedBox(height: 24),
              _buildRequestsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with Donation History button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Inventory',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDonationsScreen(),
                  ),
                );
              },
              icon: Icon(Icons.history, color: Colors.red[800]),
              label: Text(
                'Donation History',
                style: TextStyle(color: Colors.red[800]),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _bloodInventory.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No blood units in inventory',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        )
            : GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _bloodInventory.length,
          itemBuilder: (context, index) {
            final item = _bloodInventory[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red[100]!,
                      Colors.red[50]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['blood_group'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${item['units'] ?? 0} units',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Last updated: ${item['updated_at'] != null ? DateFormat('MMM d').format(DateTime.parse(item['updated_at'])) : 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showUpdateInventoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Update Inventory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Blood Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red[800],
          ),
        ),
        SizedBox(height: 16),
        _pendingRequests.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No pending blood requests',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        )
            : ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _pendingRequests.length,
          itemBuilder: (context, index) {
            final request = _pendingRequests[index];
            final String bloodGroup = request['bloodGroup'] ??
                request['blood_group'] ??
                request['blood_type'] ?? 'Unknown';
            final int quantity = request['quantity'] ?? 1;

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red[50],
                          radius: 24,
                          child: Text(
                            bloodGroup,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request for ${bloodGroup} Blood',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Needed by: ${DateFormat('MMM d, yyyy').format(
                                  DateTime.parse(
                                    request['needByDate'] ??
                                        request['need_by_date'] ??
                                        request['needed_by'] ??
                                        DateTime.now().toString(),
                                  ),
                                )}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),
                    _buildInfoRow('Required Units', '$quantity'),
                    _buildInfoRow('Patient Name', request['patientName'] ?? 'Not specified'),
                    _buildInfoRow('Location', request['address'] ?? 'Not specified'),
                    _buildInfoRow('Contact', request['contact'] ?? request['requester_phone'] ?? 'Not specified'),

                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _fulfillRequest(
                          request['id'],
                          bloodGroup,
                          quantity,
                        ),
                        child: Text(
                          'FULFILL FROM INVENTORY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}