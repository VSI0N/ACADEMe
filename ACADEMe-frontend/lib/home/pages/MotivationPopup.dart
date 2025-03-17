import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ASKMe.dart';

void showMotivationPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return const MotivationPopup();
    },
  );
}

class MotivationPopup extends StatefulWidget {
  const MotivationPopup({Key? key}) : super(key: key);

  @override
  _MotivationPopupState createState() => _MotivationPopupState();
}

class _MotivationPopupState extends State<MotivationPopup> {
  late Future<String> _recommendationFuture;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recommendationFuture = _fetchRecommendations();
  }

  /// **Fetch recommendations from the backend**
  Future<String> _fetchRecommendations() async {
    final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await const FlutterSecureStorage().read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse("$backendUrl/api/recommendations/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["recommendations"];
    } else {
      throw Exception("❌ Failed to fetch recommendations: ${response.statusCode}");
    }
  }


  void _sendFollowUpToChatbot() async {
    String followUpMessage = _messageController.text.trim();
    if (followUpMessage.isNotEmpty) {
      String recommendationText = "";
      try {
        recommendationText = await _recommendationFuture;
      } catch (error) {
        recommendationText = "⚠️ Error fetching recommendation. Please try again.";
      }

      // Combine Recommendation + Follow-up
      String fullMessage = "📊 Recommendation: \n$recommendationText\n\n🗨️ Follow-up: $followUpMessage";

      // Navigate to Chatbot Screen with message
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ASKMe(initialMessage: fullMessage),
        ),
      );

      _messageController.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // **Scrollable Content (Fetched Data)**
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<String>(
                    future: _recommendationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return _errorView();
                      }
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "📊 Your Progress Analysis",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _formattedText(snapshot.data!),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // **Message Input Field (Fixed at Bottom)**
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context)
                      .viewInsets
                      .bottom, // Moves input above keyboard
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  child: Row(
                    children: [
                      // **Message Input Box**
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Ask follow-up...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // **Send Button**
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _sendFollowUpToChatbot, // Directly call the function
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  /// **Error View when API fails**
  Widget _errorView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "⚠️ Failed to load recommendations. Please try again.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      ),
    );
  }

  /// **Formats raw recommendation text with bold headings and bullet points**
  Widget _formattedText(String text) {
    List<Widget> formattedWidgets = [];
    List<String> parts = text.split("\n");

    for (String part in parts) {
      if (part.trim().isEmpty) {
        formattedWidgets.add(const SizedBox(height: 8)); // Adds spacing
      } else if (part.startsWith("**") && part.endsWith("**")) {
        formattedWidgets.add(Text(
          part.replaceAll("**", ""),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ));
      } else if (part.startsWith("- ")) {
        formattedWidgets.add(_buildBulletPoint(part.replaceFirst("- ", "")));
      } else {
        formattedWidgets.add(Text(
          part,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedWidgets,
    );
  }

  /// **Helper function for bullet points**
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
