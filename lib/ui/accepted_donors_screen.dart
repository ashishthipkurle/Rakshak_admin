import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Servers/admin_api.dart';

class AcceptedDonorsScreen extends StatefulWidget {
  const AcceptedDonorsScreen({Key? key}) : super(key: key);

  @override
  State<AcceptedDonorsScreen> createState() => _AcceptedDonorsScreenState();
}

class _AcceptedDonorsScreenState extends State<AcceptedDonorsScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  bool _isLoading = false;
  List _acceptedDonations = [];
  List _filteredDonations = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchAcceptedDonations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAcceptedDonations() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _searchController.clear();
    });

    try {
      final donations = await _adminApiService.getAcceptedDonations();
      setState(() {
        _acceptedDonations = donations;
        _filteredDonations = donations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching accepted donations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDonations(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredDonations = _acceptedDonations;
      } else {
        _filteredDonations = _acceptedDonations.where((donation) {
          final phone = donation['donor_phone'] ?? '';
          return phone.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
          'Accepted Donors',
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchAcceptedDonations,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by phone number',
                prefixIcon: Icon(Icons.search, color: Colors.red[700]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterDonations('');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.red.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterDonations,
            ),
          ),
          if (_isSearching && _filteredDonations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No donors found with that phone number',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.red))
                : _filteredDonations.isEmpty && !_isSearching
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    size: 80,
                    color: Colors.red[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No accepted donations found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _filteredDonations.length,
              itemBuilder: (context, index) {
                final donation = _filteredDonations[index];
                final request = donation['blood_request'];
                final donor = donation['donor_details'];

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
                                donor?['blood_group'] ?? 'U',
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
                                    donor?['name'] ?? 'Anonymous Donor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Donated on: ${DateFormat('MMM d, yyyy').format(
                                      DateTime.parse(donation['offer_date']),
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
                        _buildInfoRow('Donor Phone', donation['donor_phone']),
                        if (donor != null) ...[
                          _buildInfoRow('Blood Group', donor['blood_group'] ?? 'N/A'),
                          _buildInfoRow('Total Donations', donor['total_donations']?.toString() ?? '1'),
                        ],
                        if (request != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Request Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow('Blood Group',
                              request['bloodGroup'] ??
                                  request['blood_group'] ??
                                  request['blood_type'] ??
                                  request['bloodType'] ??
                                  'N/A'),
                          _buildInfoRow('Quantity', '${request['quantity']} units'),
                          _buildInfoRow('Location', request['address'] ?? 'Not specified'),
                          _buildInfoRow(
                            'Needed by',
                            request['needByDate'] != null
                                ? DateFormat('MMM d, yyyy').format(DateTime.parse(request['needByDate']))
                                : request['need_by_date'] != null
                                ? DateFormat('MMM d, yyyy').format(DateTime.parse(request['need_by_date']))
                                : request['needed_by'] != null
                                ? DateFormat('MMM d, yyyy').format(DateTime.parse(request['needed_by']))
                                : request['date_needed'] != null
                                ? DateFormat('MMM d, yyyy').format(DateTime.parse(request['date_needed']))
                                : 'N/A',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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