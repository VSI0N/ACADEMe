import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClassSelectionBottomSheet extends StatefulWidget {
  final VoidCallback onClassSelected;

  const ClassSelectionBottomSheet({
    super.key,
    required this.onClassSelected,
  });

  @override
  State<ClassSelectionBottomSheet> createState() =>
      _ClassSelectionBottomSheetState();
}

class _ClassSelectionBottomSheetState extends State<ClassSelectionBottomSheet> {
  String? selectedClass;
  final List<String> classes = ['5'];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _handleClassSelection,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Confirm",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _handleClassSelection() async {
    if (selectedClass == null) {
      if (mounted) {
        _showSnackBar('Please select a class');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _updateClassInBackend(selectedClass!);
      if (success) {
        if (mounted) {
          _showSnackBar('Selected $selectedClass');
          widget.onClassSelected();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to update class');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _updateClassInBackend(String selectedClass) async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      if (mounted) {
        _showSnackBar('No access token found');
      }
      return false;
    }

    try {
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
        return await _reloginUser();
      } else {
        if (mounted) {
          _showSnackBar('Failed to update class: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      debugPrint("Error updating class: $e");
      if (mounted) {
        _showSnackBar('An error occurred. Please try again.');
      }
      return false;
    }
  }

  Future<bool> _reloginUser() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? email = await _secureStorage.read(key: 'email');
    final String? password = await _secureStorage.read(key: 'password');

    if (email == null || password == null) {
      if (mounted) {
        _showSnackBar('No email or password found');
      }
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
        await _secureStorage.write(
            key: 'access_token', value: responseData['access_token']);
        return true;
      } else {
        if (mounted) {
          _showSnackBar('Failed to relogin: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      debugPrint("Error relogging in: $e");
      if (mounted) {
        _showSnackBar('An error occurred. Please try again.');
      }
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

Future<void> showClassSelectionSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ClassSelectionBottomSheet(
      onClassSelected: () {
        debugPrint("Class selected");
      },
    ),
  );
}
