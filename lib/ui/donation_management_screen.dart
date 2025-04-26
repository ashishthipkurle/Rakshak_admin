import 'package:flutter/material.dart';
import '../Servers/admin_api.dart';

class DonationManagementScreen extends StatefulWidget {
  const DonationManagementScreen({Key? key}) : super(key: key);

  @override
  State<DonationManagementScreen> createState() => _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  // Date values
  String _selectedDay = '1';
  String _selectedMonth = '1';
  String _selectedYear = DateTime.now().year.toString();

  // Generate lists for dropdowns
  List<String> _getDays() => List.generate(31, (index) => (index + 1).toString());
  List<String> _getMonths() => List.generate(12, (index) => (index + 1).toString());
  List<String> _getYears() {
    int currentYear = DateTime.now().year;
    return List.generate(5, (index) => (currentYear + index).toString());
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Format date from dropdowns
      _formData['donation_date'] = "$_selectedYear-$_selectedMonth-$_selectedDay";

      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _adminApiService.uploadDonation(_formData);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation uploaded successfully!')),
          );
          _formKey.currentState?.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload donation')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(String label, {TextInputType? keyboardType, String? Function(String?)? validator, void Function(String?)? onSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.0),
          TextFormField(
            keyboardType: keyboardType,
            validator: validator,
            onSaved: onSaved,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  value: _selectedDay,
                  items: _getDays().map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDay = newValue as String;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: DropdownButtonFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  value: _selectedMonth,
                  items: _getMonths().map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedMonth = newValue as String;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: DropdownButtonFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  value: _selectedYear,
                  items: _getYears().map((String value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedYear = newValue as String;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          'Rakshak Admin',
          style: TextStyle(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(16.0),
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bloodtype,
                    size: 100,
                    color: Colors.red[700],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Donation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  _buildTextField(
                    'Contact Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => _formData['phone_number'] = value,
                  ),
                  _buildTextField(
                    'Blood Group',
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => _formData['blood_group'] = value,
                  ),
                  _buildDateField(),
                  _buildTextField(
                    'Upper Blood Pressure',
                    keyboardType: TextInputType.number,
                    onSaved: (value) => value?.isNotEmpty == true ?
                    _formData['upper_bp'] = int.tryParse(value!) : null,
                  ),
                  _buildTextField(
                    'Lower Blood Pressure',
                    keyboardType: TextInputType.number,
                    onSaved: (value) => value?.isNotEmpty == true ?
                    _formData['lower_bp'] = int.tryParse(value!) : null,
                  ),
                  _buildTextField(
                    'Location',
                    onSaved: (value) => _formData['location'] = value,
                  ),
                  SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[500],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}