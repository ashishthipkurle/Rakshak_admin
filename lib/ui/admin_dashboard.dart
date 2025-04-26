import 'package:flutter/material.dart';
import '../ui/donation_offers_screen.dart';
import '../ui/accepted_donors_screen.dart';
import '../ui/event_management_screen.dart';
import '../ui/blood_bank_management_screen.dart';
import '../ui/donation_management_screen.dart';
import '../ui/blood_bank_inventory_screen.dart'; // Add this import

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF7F6),
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.bloodtype, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Rakshak Admin',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8E6E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/img.png",
                      height: 300,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.volunteer_activism, size: 80, color: Colors.red);
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      "\"Managing blood donations to save lives\"",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // First row - Events and Blood Bank
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EventManagementScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.event, size: 50, color: Colors.teal),
                            SizedBox(height: 8),
                            Text(
                              "Events",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Blood Bank moved to the middle (first row, second column)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BloodBankManagementScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.location_on, size: 50, color: Colors.pink),
                            SizedBox(height: 8),
                            Text(
                              "Blood Banks",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Second row - Donation and Donation Offers
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DonationManagementScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.bloodtype, size: 50, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              "Donation",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DonationOffersScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.local_offer, size: 50, color: Colors.red.shade800),
                            SizedBox(height: 8),
                            Text(
                              "Donation Offers",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Third row - Accepted Donors and Blood Bank Inventory
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AcceptedDonorsScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.verified_user, size: 50, color: Colors.blue.shade800),
                            SizedBox(height: 8),
                            Text(
                              "Accepted Donors",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Replace empty space with Blood Bank Inventory
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BloodBankInventoryScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.inventory, size: 50, color: Colors.purple),
                            SizedBox(height: 8),
                            Text(
                              "Bank Inventory and donation history",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}