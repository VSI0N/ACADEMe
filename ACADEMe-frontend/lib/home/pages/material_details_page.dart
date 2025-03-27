import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MaterialDetailsPage extends StatefulWidget {
  final String materialId;
  const MaterialDetailsPage({super.key, required this.materialId});

  @override
  _MaterialDetailsPageState createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = 'http://10.0.2.2:8000';
  Map<String, dynamic>? materialDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMaterialDetails();
  }

  Future<void> fetchMaterialDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/materials/${widget.materialId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          materialDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch material details");
      }
    } catch (e) {
      print("❌ Error fetching material details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Material Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materialDetails?["title"] ?? "Untitled Material",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Type: ${materialDetails?["type"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Category: ${materialDetails?["category"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    materialDetails?["content"] ?? "No content available.",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
