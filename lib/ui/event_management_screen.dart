import 'package:flutter/material.dart';
import '../Servers/admin_api.dart';
import 'package:intl/intl.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({Key? key}) : super(key: key);

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
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
      _formData['date'] = "$_selectedDay/$_selectedMonth/$_selectedYear";

      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _adminApiService.uploadEvent(_formData);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event uploaded successfully!')),
          );
          _formKey.currentState?.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload event')),
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
                  Icons.event,
                  size: 80,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add Event ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  filled: true,
                  fillColor: Colors.grey[200],
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
                  labelText: 'Description',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                onSaved: (value) => _formData['description'] = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                onSaved: (value) => _formData['location'] = value,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Day',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Month',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Year',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  filled: true,
                  fillColor: Colors.grey[200],
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
                  fillColor: Colors.grey[200],
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