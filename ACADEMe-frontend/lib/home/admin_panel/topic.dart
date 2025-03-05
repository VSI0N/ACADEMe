import 'dart:io';

import 'package:ACADEMe/home/admin_panel/TopicQuiz.dart';
import 'package:ACADEMe/home/admin_panel/subtopic.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'material.dart';

class TopicScreen extends StatefulWidget {
  final String courseTitle;

  TopicScreen({required this.courseTitle});

  @override
  _TopicScreenState createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  List<Map<String, String>> topics = [];
  List<Map<String, String>> materials = [];
  bool isMenuOpen = false;
  late MaterialManager materialManager;

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    materialManager = MaterialManager(
      context: context,
      onMaterialAdded: () {
        setState(() {}); // Refresh UI when a material is added
      },
      materials: materials, // Pass the shared materials list
    );
  }

  void _addTopic() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController subtopicController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text("Add Topic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subtopicController,
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
              onPressed: () {
                if (subtopicController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  setState(() {
                    topics.add({
                      "topic": subtopicController.text,
                      "description": descriptionController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addMaterial() {
    materialManager.addMaterial();
  }

  void _addQuiz() {
    setState(() {
      topics.add({
        "topic": "Topic Quiz",
        "description": "Quiz related to the topic",
      });
    });
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
                children: [
                  if (topics.isNotEmpty) ...[
                    Text("topic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                    ...topics.map((topic) => Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(topic["topic"]!),
                        subtitle: Text(topic["description"]!),
                        onTap: () {
                          if (topic["topic"] == "Topic Quiz") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(courseTitle: widget.courseTitle),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubtopicScreen(
                                  courseTitle: widget.courseTitle,
                                  topicTitle: topic["topic"]!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    )),
                  ],
                  if (materials.isNotEmpty) ...[
                    Text("Materials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ...materials.map((material) => Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(material["type"]!),
                        subtitle: Text(material["category"]!),
                      ),
                    )),
                  ],
                ],
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
            _buildMenuItem("Add Material", Icons.insert_drive_file, _addMaterial),
            _buildMenuItem("Add Quiz", Icons.quiz, _addQuiz),
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
