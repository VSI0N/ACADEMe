import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClassSelectionBottomSheet extends StatefulWidget {
  final VoidCallback onClassSelected; // Callback when class is selected

  const ClassSelectionBottomSheet({Key? key, required this.onClassSelected})
      : super(key: key);

  @override
  _ClassSelectionBottomSheetState createState() =>
      _ClassSelectionBottomSheetState();
}

class _ClassSelectionBottomSheetState extends State<ClassSelectionBottomSheet> {
  String? selectedClass;
  final List<String> classes = [
    'SELECT',
    ...List.generate(12, (index) => '${index + 1}')
  ]; // Add "SELECT" option
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: MediaQuery.of(context).size.height * 0.35,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "What class are you in?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text("Select class"),
            value: selectedClass,
            items: classes
                .map((className) => DropdownMenuItem(
              value: className,
              child: Text(className),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedClass = value;
              });
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (selectedClass != null && selectedClass != 'SELECT') {
                // Show confirmation dialog
                bool confirm = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text(
                        'Are you sure you want to change your class?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      content: const Text(
                        'All your progress data will be erased for this class.',
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Return false
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true); // Return true
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  // Call backend
                  bool success = await _updateClassInBackend(selectedClass!);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected $selectedClass')),
                    );
                    widget.onClassSelected();
                    print("Callback triggered: Class updated to $selectedClass");
                    Navigator.pop(context); // Close BottomSheet
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update class')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a valid class')),
                );
              }
            },
            child: const Text(
              "Confirm",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          SizedBox(height: 10,),
          if (selectedClass == null || selectedClass == 'SELECT')
            _buildImportantInfoPopup(
                context), // Show Important Info Popup only if no class is selected
        ],
      ),
    );
  }

  Future<bool> _updateClassInBackend(String selectedClass) async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No access token found')),
      );
      return false;
    }

    try {
      // Update the class
      final response = await http.patch(
        Uri.parse("$backendUrl/api/users/update_class/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'new_class': selectedClass,
        }),
      );

      if (response.statusCode == 200) {
        // Relogin the user
        bool reloginSuccess = await _reloginUser();
        if (reloginSuccess) {
          // Update the class in secure storage
          await _secureStorage.write(
              key: 'student_class', value: selectedClass);
          return true;
        } else {
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update class: ${response.body}')),
        );
        return false;
      }
    } catch (e) {
      print("Error updating class: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
      return false;
    }
  }

  Future<bool> _reloginUser() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? email = await _secureStorage.read(key: 'email');
    final String? password = await _secureStorage.read(key: 'password');

    if (email == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email or password found')),
      );
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$backendUrl/api/users/login"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String newToken = responseData['access_token'];
        await _secureStorage.write(key: 'access_token', value: newToken);
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to relogin: ${response.body}')),
        );
        return false;
      }
    } catch (e) {
      print("Error relogging in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
      return false;
    }
  }

  Widget _buildImportantInfoPopup(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Important Info",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please Select Class 5 as we currently created courses for Class 5",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}