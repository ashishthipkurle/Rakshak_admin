import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Servers/admin_api.dart';

class AdminDonationsScreen extends StatefulWidget {
  const AdminDonationsScreen({Key? key}) : super(key: key);

  @override
  _AdminDonationsScreenState createState() => _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends State<AdminDonationsScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _donations = [];
  int _totalUnits = 0;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final donations = await _apiService.getAdminDonations();
      int total = 0;

      for (var donation in donations) {
        total += (donation['units'] ?? 1) as int;
      }

      setState(() {
        _donations = donations;
        _totalUnits = total;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading donations: $e');
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
          'Admin Donation History',
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchDonations,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.red[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Donations:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_donations.length} (${_totalUnits} units)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _donations.isEmpty
                ? Center(
              child: Text(
                'No donations from inventory yet',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _donations.length,
              itemBuilder: (context, index) {
                final donation = _donations[index];
                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[100],
                      child: Text(
                        donation['blood_group'] ?? 'N/A',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${donation['units'] ?? 1} unit(s) of ${donation['blood_group']} blood',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('MMM d, yyyy').format(DateTime.parse(donation['donation_date']))}',
                        ),
                        Text(
                          'Location: ${donation['location'] ?? 'Blood Bank'}',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}