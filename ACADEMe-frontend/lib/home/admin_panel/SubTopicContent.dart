import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'SubtopicQuiz.dart';
import 'material.dart';

class SubtopicContentScreen extends StatefulWidget {
  final String courseTitle;
  final String topicTitle;
  final String subtopicTitle;
  final String content;

  SubtopicContentScreen({
    required this.courseTitle,
    required this.topicTitle,
    required this.subtopicTitle,
    required this.content,
  });

  @override
  _SubtopicContentScreenState createState() => _SubtopicContentScreenState();
}

class _SubtopicContentScreenState extends State<SubtopicContentScreen> {
  List<Map<String, String>> materials = [];
  bool isMenuOpen = false;
  late MaterialManager materialManager;

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

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void _addMaterial() {
    materialManager.addMaterial();
  }

  void _addQuiz() {
    setState(() {
      materials.add({
        "type": "Quiz",
        "category": "Quiz related to this subtopic",
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > ${widget.topicTitle}",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (materials.isNotEmpty) ...[
              Text("Materials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...materials.map((material) => Card(
                margin: EdgeInsets.only(top: 10),
                child: ListTile(
                  title: Text(material["type"]!),
                  subtitle: Text(material["category"]!),
                  onTap: () {
                    if (material["type"] == "Quiz") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubTopicQuizScreen(
                            courseTitle: widget.courseTitle,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("This is a material, not a quiz.")),
                      );
                    }
                  },
                ),
              )),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMenuOpen) ...[
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
