import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/admin_panel/subtopic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TopicScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  TopicScreen({required this.courseId, required this.courseTitle});

  @override
  _TopicScreenState createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  List<Map<String, dynamic>> topics = [];
  bool isMenuOpen = false;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void _loadTopics() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      print("No access token found");
      return;
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        topics = data.map((item) => {
          "id": item["id"].toString(),
          "title": item["title"],
          "description": item["description"],
        }).toList();
      });
    } else {
      print("Failed to fetch topics: ${response.body}");
    }
  }

  void _addTopic() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text("Add Topic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Topic Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String? token = await _storage.read(key: "access_token");
                if (token == null) {
                  print("No access token found");
                  return;
                }

                final response = await http.post(
                  Uri.parse('${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/'),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },
                  body: json.encode({
                    "title": titleController.text,
                    "description": descriptionController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  _loadTopics();
                  Navigator.pop(context);
                } else {
                  print("Failed to add topic: ${response.body}");
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} >",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Topic List",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: topics.map((topic) => Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(topic["title"]!),
                    subtitle: Text(topic["description"]!),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubtopicScreen(
                            courseTitle: widget.courseTitle,
                            topicTitle: topic["title"]!,
                          ),
                        ),
                      );
                    },
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMenuOpen) ...[
            _buildMenuItem("Add Topic", Icons.note_add, _addTopic),
            SizedBox(height: 10),
          ],
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: AcademeTheme.appColor,
            child: Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          onTap();
          _toggleMenu();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Text(label, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
