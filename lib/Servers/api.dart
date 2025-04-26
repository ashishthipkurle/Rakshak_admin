import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://xnvqeqirpztsprdiydfs.supabase.co';
  final String _apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhudnFlcWlycHp0c3ByZGl5ZGZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0NTQ0MzMsImV4cCI6MjA1NjAzMDQzM30.BNhdtVndoiRPnp6yyUJemjqKe-3GlR6o-h24EBHD4zg';

  String get baseUrl => _baseUrl;
  String get apiKey => _apiKey;

  // Get all blood requests
  Future<List> getAllRequests() async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/blood_requests?select=*&order=needByDate.asc');
      final response = await http.get(
        url,
        headers: {
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting blood requests: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting blood requests: $e');
      return [];
    }
  }

  // Make an offer to donate
  Future<bool> offerToDonate(String requestId, String donorPhone) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/donation_offers');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'request_id': requestId,
          'donor_phone': donorPhone,
          'offer_date': DateTime.now().toIso8601String(),
          'status': 'pending'
        }),
      );

      if (response.statusCode == 201) {
        // Update the request to indicate it has pending offers
        await _updateRequestWithPendingOffer(requestId, true);
        return true;
      } else {
        print('Error creating donation offer: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error offering to donate: $e');
      return false;
    }
  }

  // Update request to indicate it has pending offers
  Future<void> _updateRequestWithPendingOffer(String requestId, bool hasPendingOffers) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/blood_requests?id=eq.$requestId');
      await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'has_pending_offers': hasPendingOffers
        }),
      );
    } catch (e) {
      print('Error updating request status: $e');
    }
  }

  // Get all donation offers for a specific request
  Future<List> getDonationOffers(String requestId) async {
    try {
      final url = Uri.parse('$_baseUrl/rest/v1/donation_offers?request_id=eq.$requestId&select=*');
      final response = await http.get(
        url,
        headers: {
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        print('Found ${results.length} donation offers');
        return results;
      } else {
        print('Error getting donation offers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception getting donation offers: $e');
      return [];
    }
  }

  Future<bool> acceptDonationOffer(String offerId) async {
    try {
      // Get the offer details first to retrieve the request_id
      final offerUrl = Uri.parse('$_baseUrl/rest/v1/donation_offers?id=eq.$offerId&select=*');
      final offerResponse = await http.get(
        offerUrl,
        headers: {
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (offerResponse.statusCode != 200) {
        print('Error retrieving donation offer: ${offerResponse.statusCode}');
        return false;
      }

      final List offerData = json.decode(offerResponse.body);
      if (offerData.isEmpty) {
        print('No offer found with ID: $offerId');
        return false;
      }

      final String requestId = offerData[0]['request_id'];
      final String donorPhone = offerData[0]['donor_phone'];

      // Update the offer status to accepted
      final url = Uri.parse('$_baseUrl/rest/v1/donation_offers?id=eq.$offerId');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'status': 'accepted',
        }),
      );

      if (response.statusCode != 204) {
        print('Error accepting donation offer: ${response.statusCode}');
        return false;
      }

      // Update the blood request with the accepted donor
      final requestUrl = Uri.parse('$_baseUrl/rest/v1/blood_requests?id=eq.$requestId');
      final requestResponse = await http.patch(
        requestUrl,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'has_accepted_donor': true,
          'accepted_donor_phone': donorPhone,
        }),
      );

      if (requestResponse.statusCode != 204) {
        print('Error updating blood request: ${requestResponse.statusCode}');
      }

      // Update the donor's total donations
      await updateUserDonationCount(donorPhone);

      return true;
    } catch (e) {
      print('Error accepting donation offer: $e');
      return false;
    }
  }

  // Update a user's total donation count
  Future<bool> updateUserDonationCount(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      print('Error: phone number is required to update donation count');
      return false;
    }

    try {
      // First, query to get the current user
      final userUrl = Uri.parse('$_baseUrl/rest/v1/users?phone_number=eq.$phoneNumber');
      final getUserResponse = await http.get(
        userUrl,
        headers: {
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (getUserResponse.statusCode != 200) {
        print('Error getting user: ${getUserResponse.statusCode}');
        return false;
      }

      final userData = jsonDecode(getUserResponse.body);
      if (userData is! List || userData.isEmpty) {
        print('User with phone number $phoneNumber not found');
        return false;
      }

      // Get current donation count
      final user = userData[0];
      int currentDonations = user['total_donations'] ?? 0;
      int newDonationCount = currentDonations + 1;

      print('Updating donation count from $currentDonations to $newDonationCount');

      // Update the user with incremented donation count
      final updateUrl = Uri.parse('$_baseUrl/rest/v1/users?phone_number=eq.$phoneNumber');
      final updateResponse = await http.patch(
        updateUrl,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'total_donations': newDonationCount,
        }),
      );

      if (updateResponse.statusCode != 204) {
        print('Error updating total donations: ${updateResponse.statusCode}');
        return false;
      }

      print('Successfully updated donation count for $phoneNumber to $newDonationCount');
      return true;
    } catch (e) {
      print('Error updating user donation count: $e');
      return false;
    }
  }


}