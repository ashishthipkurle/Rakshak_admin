
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class AdminApiService extends ApiService {

  // Get all pending donation offers for admin review
  Future<List> getAllDonationOffers() async {
    try {
      // The issue is in the join syntax - we need to adjust how we're fetching related data
      final url = Uri.parse('$baseUrl/rest/v1/donation_offers?select=*&status=eq.pending');
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List offers = json.decode(response.body);
        print('Found ${offers.length} pending donation offers');

        // If we have offers, fetch the associated blood requests separately
        if (offers.isNotEmpty) {
          for (int i = 0; i < offers.length; i++) {
            final requestId = offers[i]['request_id'];
            if (requestId != null) {
              final requestUrl = Uri.parse('$baseUrl/rest/v1/blood_requests?id=eq.$requestId');
              final requestResponse = await http.get(
                requestUrl,
                headers: {
                  'apikey': apiKey,
                  'Authorization': 'Bearer $apiKey',
                },
              );

              if (requestResponse.statusCode == 200) {
                final List requests = json.decode(requestResponse.body);
                if (requests.isNotEmpty) {
                  offers[i]['blood_request'] = requests[0];
                }
              }
            }
          }
        }

        return offers;
      } else {
        print('Error getting donation offers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception getting donation offers: $e');
      return [];
    }
  }

  // Database column definitions for all tables
  final Map<String, List<String>> _defaultColumns = {
    'donations': [
      'id', 'phone_number', 'donation_date', 'upper_bp',
      'lower_bp', 'blood_group', 'location', 'created_at'
    ],
    'organizations': [
      'id', 'name', 'address', 'phone',
      'latitude', 'longitude', 'created_at'
    ],
    'events': [
      'id', 'name', 'description', 'location',
      'date', 'latitude', 'longitude', 'created_at'
    ]
  };

  // Field mappings from form fields to database columns
  final Map<String, String> _fieldMappings = {
    'date': 'donation_date',
    'donated_at': 'donation_date',
    'contact': 'phone'
  };

  // Upload an event to the database
  Future<bool> uploadEvent(Map<String, dynamic> eventData) async {
    return _uploadData(eventData, 'events');
  }

  // Upload a blood bank to the database (stored in organizations table)
  Future<bool> uploadBloodBank(Map<String, dynamic> bloodBankData) async {
    return _uploadData(bloodBankData, 'organizations');
  }

  // Upload a blood donation record to the database
  Future<bool> uploadDonation(Map<String, dynamic> formData) async {
    bool success = await _uploadData(formData, 'donations');

    if (success && formData.containsKey('phone_number')) {
      await updateUserDonationCount(formData['phone_number']);
    }

    return success;
  }

  // Get table structure from database for debugging
  Future<void> getTableStructure(String tableName) async {
    print('Table $tableName default columns: ${_defaultColumns[tableName] ?? []}');

    final url = Uri.parse('$baseUrl/rest/v1/$tableName?select=*&limit=1');
    try {
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      print('Table structure response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          print('Actual columns for $tableName: ${data[0].keys.toList()}');
        } else {
          print('No data available');
        }
      } else {
        print('Error response: ${response.body}');
      }
    } catch (e) {
      print('Error getting table structure: $e');
    }
  }

  // Unified method to process and upload data to any table
  Future<bool> _uploadData(Map<String, dynamic> formData, String tableName) async {
    // Map fields to their correct column names
    Map<String, dynamic> mappedData = {};
    formData.forEach((key, value) {
      if (_fieldMappings.containsKey(key)) {
        String targetField = _fieldMappings[key]!;
        mappedData[targetField] = value;
      } else {
        mappedData[key] = value;
      }
    });

    // Filter out fields not in the table
    final columns = _defaultColumns[tableName] ?? [];
    final filteredData = <String, dynamic>{};

    mappedData.forEach((key, value) {
      if (columns.contains(key) && value != null && value != '') {
        filteredData[key] = value;
      }
    });

    if (filteredData.isEmpty) {
      print('No valid data to submit');
      return false;
    }

    final url = Uri.parse('$baseUrl/rest/v1/$tableName');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(filteredData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error uploading to $tableName: $e');
      return false;
    }
  }

  Future<List> getAcceptedDonations() async {
    try {
      // Modified query to get all accepted offers regardless of who accepted them
      // final url = Uri.parse('$baseUrl/rest/v1/donation_offers?select=*&status=eq.accepted');
      final url = Uri.parse('$baseUrl/rest/v1/donation_offers?select=*&or=(status.eq.accepted,status.eq.admin_fulfilled)');
      // Also fetch user-accepted offers (if they use a different status)
      final userAcceptedUrl = Uri.parse('$baseUrl/rest/v1/donation_offers?select=*&status=eq.user_accepted');

      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      final userAcceptedResponse = await http.get(
        userAcceptedUrl,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      List allOffers = [];

      if (response.statusCode == 200) {
        final List adminAcceptedOffers = json.decode(response.body);
        allOffers.addAll(adminAcceptedOffers);
      }

      if (userAcceptedResponse.statusCode == 200) {
        final List userAcceptedOffers = json.decode(userAcceptedResponse.body);
        allOffers.addAll(userAcceptedOffers);
      }

      print('Found ${allOffers.length} total accepted donation offers');

      // Fetch related data for each offer
      if (allOffers.isNotEmpty) {
        for (int i = 0; i < allOffers.length; i++) {
          final requestId = allOffers[i]['request_id'];
          if (requestId != null) {
            // Fetch blood request details
            final requestUrl = Uri.parse('$baseUrl/rest/v1/blood_requests?id=eq.$requestId');
            final requestResponse = await http.get(
              requestUrl,
              headers: {
                'apikey': apiKey,
                'Authorization': 'Bearer $apiKey',
              },
            );

            if (requestResponse.statusCode == 200) {
              final List requests = json.decode(requestResponse.body);
              if (requests.isNotEmpty) {
                allOffers[i]['blood_request'] = requests[0];
              }
            }

            // Fetch donor details
            final donorPhone = allOffers[i]['donor_phone'];
            if (donorPhone != null) {
              final donorUrl = Uri.parse('$baseUrl/rest/v1/users?phone_number=eq.$donorPhone');
              final donorResponse = await http.get(
                donorUrl,
                headers: {
                  'apikey': apiKey,
                  'Authorization': 'Bearer $apiKey',
                },
              );

              if (donorResponse.statusCode == 200) {
                final List donors = json.decode(donorResponse.body);
                if (donors.isNotEmpty) {
                  allOffers[i]['donor_details'] = donors[0];
                }
              }
            }
          }
        }
      }
      return allOffers;
    } catch (e) {
      print('Exception getting accepted donations: $e');
      return [];
    }
  }

  // Add these methods to your AdminApiService class

  Future<List<Map<String, dynamic>>> getBloodInventory() async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/blood_inventory?select=*');
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error fetching blood inventory: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load blood inventory');
      }
    } catch (e) {
      print('Exception fetching blood inventory: $e');
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingBloodRequests() async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/blood_requests?select=*&status=eq.pending');
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error fetching pending requests: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load pending requests');
      }
    } catch (e) {
      print('Exception fetching pending requests: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> fulfillBloodRequest({
    required String requestId,
    required String bloodGroup,
    required int units,
  }) async {
    try {
      // 1. First ensure inventory exists for this blood group
      final inventoryExists = await ensureBloodInventoryExists(bloodGroup, initialUnits: units);
      if (!inventoryExists) {
        print('Error: Could not ensure inventory for blood group $bloodGroup');
        return false;
      }

      // 2. Now check if inventory has enough units
      final encodedBloodGroup = Uri.encodeComponent(bloodGroup);
      final inventoryUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory?blood_group=eq.$encodedBloodGroup');
      final inventoryResponse = await http.get(
        inventoryUrl,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (inventoryResponse.statusCode == 200) {
        final List inventoryData = json.decode(inventoryResponse.body);

        // Check if inventory data exists before accessing it
        if (inventoryData.isEmpty) {
          print('Error: No inventory data found for blood group $bloodGroup');
          return false;
        }

        final Map<String, dynamic> inventory = inventoryData[0];
        final int availableUnits = inventory['units'] ?? 0;

        if (availableUnits < units) {
          print('Error: Not enough units available. Available: $availableUnits, Needed: $units');
          return false;
        }

        // Get request details to use for the donation record
        final requestDetailsUrl = Uri.parse('$baseUrl/rest/v1/blood_requests?id=eq.$requestId');
        final requestDetailsResponse = await http.get(
          requestDetailsUrl,
          headers: {
            'apikey': apiKey,
            'Authorization': 'Bearer $apiKey',
          },
        );

        Map<String, dynamic> requestDetails = {};
        if (requestDetailsResponse.statusCode == 200) {
          final List data = json.decode(requestDetailsResponse.body);
          if (data.isNotEmpty) {
            requestDetails = data[0];
          }
        }

        // Update inventory by decreasing units
        final updateUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory?id=eq.${inventory['id']}');
        final updateResponse = await http.patch(
          updateUrl,
          headers: {
            'apikey': apiKey,
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
          },
          body: json.encode({'units': availableUnits - units}),
        );

        if (updateResponse.statusCode != 204) {
          print('Failed to update inventory: ${updateResponse.statusCode}');
          return false;
        }

        // Update the request status to fulfilled and set fulfilled_by to "Admin"
        final requestUrl = Uri.parse('$baseUrl/rest/v1/blood_requests?id=eq.$requestId');
        final requestUpdateResponse = await http.patch(
          requestUrl,
          headers: {
            'apikey': apiKey,
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
          },
          body: json.encode({
            'status': 'fulfilled',
            'fulfilled_by': 'Admin'
          }),
        );

        if (requestUpdateResponse.statusCode != 204) {
          print('Failed to update request status: ${requestUpdateResponse.statusCode}');
          return false;
        }

        // Create a donation offer record
        final createOfferUrl = Uri.parse('$baseUrl/rest/v1/donation_offers');
        final offerResponse = await http.post(
          createOfferUrl,
          headers: {
            'apikey': apiKey,
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'request_id': requestId,
            'donor_phone': 'Admin',
            'offer_date': DateTime.now().toIso8601String(),
            'status': 'accepted'
          }),
        );

        // Record the donation in donations table
        final donationsUrl = Uri.parse('$baseUrl/rest/v1/donations');
        final donationResponse = await http.post(
          donationsUrl,
          headers: {
            'apikey': apiKey,
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'phone_number': 'Admin',
            'blood_group': bloodGroup,
            'donation_date': DateTime.now().toIso8601String(),
            'location': requestDetails['address'] ?? 'Blood Bank',
            'request_id': requestId,
            'admin_fulfilled': true,
            'units': units
          }),
        );

        if (donationResponse.statusCode != 201) {
          print('Failed to record admin donation: ${donationResponse.statusCode}');
          print('Response body: ${donationResponse.body}');
          // Continue anyway since request was fulfilled
        }

        return true;
      } else {
        print('Failed to fetch inventory: ${inventoryResponse.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception fulfilling request: $e');
      return false;
    }
  }
  // Future<bool> fulfillBloodRequest({
  //   required String requestId,
  //   required String bloodGroup,
  //   required int units,
  // }) async {
  //   try {
  //     // 1. Check if inventory exists for this blood group
  //     final inventoryUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory?blood_group=eq.$bloodGroup');
  //     final inventoryResponse = await http.get(
  //       inventoryUrl,
  //       headers: {
  //         'apikey': apiKey,
  //         'Authorization': 'Bearer $apiKey',
  //       },
  //     );
  //
  //     if (inventoryResponse.statusCode == 200) {
  //       final List inventoryData = json.decode(inventoryResponse.body);
  //
  //       if (inventoryData.isEmpty) {
  //         print('Error: No inventory for blood group $bloodGroup');
  //         return false;
  //       } else {
  //         // Update existing inventory by decreasing units
  //         final Map<String, dynamic> inventory = inventoryData[0];
  //         final int currentUnits = inventory['units'] ?? 0;
  //
  //         if (currentUnits < units) {
  //           print('Not enough units in inventory. Available: $currentUnits, Needed: $units');
  //           return false;
  //         }
  //
  //         // Decrease inventory - this is where the fix is needed
  //         final updateUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory?id=eq.${inventory['id']}');
  //         final updateResponse = await http.patch(
  //           updateUrl,
  //           headers: {
  //             'apikey': apiKey,
  //             'Authorization': 'Bearer $apiKey',
  //             'Content-Type': 'application/json',
  //             'Prefer': 'return=minimal'
  //           },
  //           body: json.encode({'units': currentUnits - units}), // SUBTRACT units here
  //         );
  //
  //         if (updateResponse.statusCode != 204) {
  //           print('Failed to update inventory: ${updateResponse.statusCode}');
  //           return false;
  //         }
  //       }
  //
  //       // 2. Update the request status to fulfilled
  //       final requestUrl = Uri.parse('$baseUrl/rest/v1/blood_requests?id=eq.$requestId');
  //       final updateResponse = await http.patch(
  //         requestUrl,
  //         headers: {
  //           'apikey': apiKey,
  //           'Authorization': 'Bearer $apiKey',
  //           'Content-Type': 'application/json',
  //           'Prefer': 'return=minimal'
  //         },
  //         body: json.encode({'status': 'fulfilled'}),
  //       );
  //
  //       if (updateResponse.statusCode != 204) {
  //         print('Failed to update request status: ${updateResponse.statusCode}');
  //         return false;
  //       }
  //
  //       return true;
  //     } else {
  //       print('Failed to fetch inventory: ${inventoryResponse.statusCode}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Exception fulfilling request: $e');
  //     return false;
  //   }
  // }


  Future<bool> ensureBloodInventoryExists(String bloodGroup, {int initialUnits = 0}) async {
    try {
      print('Ensuring inventory exists for blood group: $bloodGroup');

      // Properly encode the blood group for URL
      final encodedBloodGroup = Uri.encodeComponent(bloodGroup);
      final inventoryUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory?blood_group=eq.$encodedBloodGroup');

      // Rest of method remains the same
      final response = await http.get(
        inventoryUrl,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print('Inventory check: Found ${data.length} records for $bloodGroup');

        // If inventory doesn't exist, create it directly using RPC call
        if (data.isEmpty) {
          print('Creating new inventory for blood group: $bloodGroup with $initialUnits units');

          // Use RPC function to guarantee record creation
          final rpcUrl = Uri.parse('$baseUrl/rest/v1/rpc/create_blood_inventory');
          final rpcResponse = await http.post(
            rpcUrl,
            headers: {
              'apikey': apiKey,
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: json.encode({
              'p_blood_group': bloodGroup,
              'p_initial_units': initialUnits
            }),
          );

          print('RPC response code: ${rpcResponse.statusCode}');
          print('RPC response body: ${rpcResponse.body}');

          if (rpcResponse.statusCode != 200 && rpcResponse.statusCode != 201) {
            // Fallback to direct insertion
            final createUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory');
            final createResponse = await http.post(
              createUrl,
              headers: {
                'apikey': apiKey,
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation',
              },
              body: json.encode({
                'blood_group': bloodGroup,
                'units': initialUnits
              }),
            );

            print('Direct insert response: ${createResponse.statusCode}');
            return createResponse.statusCode == 201;
          }
          return true;
        }
        return true; // Inventory already exists
      }
      return false;
    } catch (e) {
      print('Error ensuring blood inventory: $e');
      return false;
    }
  }

  Future<bool> updateBloodInventory({
    required String bloodGroup,
    required int units,
  }) async {
    try {
      // Properly encode the blood group for URL
      final encodedBloodGroup = Uri.encodeComponent(bloodGroup);
      final url = Uri.parse('$baseUrl/rest/v1/blood_inventory?blood_group=eq.$encodedBloodGroup');
      await ensureBloodInventoryExists(bloodGroup);

      // Rest of method remains the same
      final checkResponse = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );
      if (checkResponse.statusCode == 200) {
        final List inventoryData = json.decode(checkResponse.body);

        if (inventoryData.isEmpty) {

          final createUrl = Uri.parse('$baseUrl/rest/v1/blood_inventory');
          final createResponse = await http.post(
            createUrl,
            headers: {
              'apikey': apiKey,
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal'
            },
            body: json.encode({
              'blood_group': bloodGroup,
              'units': units,
              'last_updated': DateTime.now().toIso8601String(),
            }),
          );

          return createResponse.statusCode == 201;
        } else {
          // Update existing inventory record
          final currentUnits = inventoryData[0]['units'] as int;
          final updateResponse = await http.patch(
            url,
            headers: {
              'apikey': apiKey,
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal'
            },
            body: json.encode({
              'units': currentUnits + units,
              'last_updated': DateTime.now().toIso8601String(),
            }),
          );

          return updateResponse.statusCode == 204;
        }
      }
      return false;
    } catch (e) {
      print('Exception updating inventory: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminDonations() async {
    try {
      final url = Uri.parse('$baseUrl/rest/v1/donations?phone_number=eq.Admin&select=*&order=donation_date.desc');
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error fetching admin donations: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching admin donations: $e');
      return [];
    }
  }


}