import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Servers/admin_api.dart';

class DonationOffersScreen extends StatefulWidget {
  const DonationOffersScreen({Key? key}) : super(key: key);

  @override
  State<DonationOffersScreen> createState() => _DonationOffersScreenState();
}

class _DonationOffersScreenState extends State<DonationOffersScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  bool _isLoading = false;
  List _donationOffers = [];

  @override
  void initState() {
    super.initState();
    _fetchDonationOffers();
  }

  Future<void> _fetchDonationOffers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offers = await _adminApiService.getAllDonationOffers();
      setState(() {
        _donationOffers = offers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching donation offers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOffer(String offerId, String donorPhone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _adminApiService.acceptDonationOffer(offerId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation offer accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the list
        await _fetchDonationOffers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept donation offer'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error accepting offer: $e');
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
          'Pending Donation Offers',
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchDonationOffers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : _donationOffers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 80,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Text(
              'No pending donation offers',
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
        itemCount: _donationOffers.length,
        itemBuilder: (context, index) {
          final offer = _donationOffers[index];
          final request = offer['blood_requests'];

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
                          request?['bloodGroup'] ?? 'U',
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
                              'Blood ${request?['bloodGroup'] ?? 'Unknown'} Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Offer Date: ${DateFormat('MMM d, yyyy').format(
                                DateTime.parse(offer['offer_date']),
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
                  _buildInfoRow('Donor Phone', offer['donor_phone']),
                  _buildInfoRow('Status', offer['status']),
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
                    _buildInfoRow('Blood Type', request['bloodType']),
                    _buildInfoRow('Quantity', '${request['quantity']} units'),
                    _buildInfoRow('Location', request['address'] ?? 'Not specified'),
                    _buildInfoRow(
                      'Needed by',
                      DateFormat('MMM d, yyyy').format(
                        DateTime.parse(request['needByDate']),
                      ),
                    ),
                  ],
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
                      onPressed: () => _acceptOffer(
                        offer['id'],
                        offer['donor_phone'],
                      ),
                      child: Text(
                        'ACCEPT',
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