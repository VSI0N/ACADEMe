import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'SubTopicContent.dart';
import 'SubtopicQuiz.dart';
import 'material.dart';

class SubtopicScreen extends StatefulWidget {
  final String courseTitle;
  final String topicTitle;

  SubtopicScreen({required this.courseTitle, required this.topicTitle});

  @override
  _SubtopicScreenState createState() => _SubtopicScreenState();
}


class _SubtopicScreenState extends State<SubtopicScreen> {
  List<Map<String, String>> subtopics = [];
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

  void _addSubtopic() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController subtopicController = TextEditingController();
        final TextEditingController contentController = TextEditingController();

        return AlertDialog(
          title: Text("Add Subtopic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subtopicController,
                decoration: InputDecoration(labelText: "Subtopic Name"),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: "Content"),
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
                if (subtopicController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  setState(() {
                    subtopics.add({
                      "subtopic": subtopicController.text,
                      "content": contentController.text,
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
    // Logic to add material
    materialManager.addMaterial();
  }

  void _addQuiz() {
    setState(() {
      subtopics.add({
        "subtopic": "Topic Quiz",
        "content": "Quiz related to the topic",
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > ${widget.topicTitle} >",
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
                  "Subtopic List",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded( // ✅ This wraps the ListView to prevent overflow
              child: ListView(
                children: [
                  if (subtopics.isNotEmpty) ...[
                    Text("subtopic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                    ...subtopics.map((topic) => Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(topic["subtopic"]!),
                        subtitle: Text(topic["content"]!),
                        onTap: () {
                          if (topic["subtopic"] == "Topic Quiz") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubTopicQuizScreen(
                                  courseTitle: widget.courseTitle,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubtopicContentScreen(
                                  courseTitle: widget.courseTitle,
                                  topicTitle: widget.topicTitle,
                                  subtopicTitle: topic["subtopic"]!,
                                  content: topic["content"]!,
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
            _buildMenuItem("Add Subtopic", Icons.note_add, _addSubtopic),
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