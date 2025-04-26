import 'package:flutter/material.dart';
import '../Servers/admin_api.dart';

class BloodBankManagementScreen extends StatefulWidget {
  const BloodBankManagementScreen({Key? key}) : super(key: key);

  @override
  State<BloodBankManagementScreen> createState() => _BloodBankManagementScreenState();
}

class _BloodBankManagementScreenState extends State<BloodBankManagementScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _adminApiService.uploadBloodBank(_formData);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blood Bank uploaded successfully!')),
          );
          _formKey.currentState?.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload Blood Bank')),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Icon(
                  Icons.bloodtype,
                  size: 80,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add Blood Bank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _formData['name'] = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _formData['address'] = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contact',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _formData['contact'] = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _formData['latitude'] = double.tryParse(value ?? '0'),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _formData['longitude'] = double.tryParse(value ?? '0'),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'ADD',
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
      ),
    );
  }
}