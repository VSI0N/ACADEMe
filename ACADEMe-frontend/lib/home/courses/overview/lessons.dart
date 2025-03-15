import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/flashcard.dart';
import 'package:ACADEMe/home/courses/overview/quiz.dart';
import 'package:ACADEMe/home/pages/material_details_page.dart';
import 'package:ACADEMe/home/pages/quiz_details_page.dart';

class LessonsSection extends StatefulWidget {
  final String courseId;
  final String topicId;

  const LessonsSection({super.key, required this.courseId, required this.topicId});

  @override
  _LessonsSectionState createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<LessonsSection> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = 'http://10.0.2.2:8000';

  Map<String, bool> isExpanded = {};
  Map<String, String> subtopicIds = {}; // Maps section titles to subtopic IDs
  Map<String, List<Map<String, dynamic>>> subtopicMaterials = {};
  Map<String, List<Map<String, dynamic>>> subtopicQuizzes = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubtopics();
  }

  Future<void> fetchSubtopics() async {
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          isExpanded = {
            for (int i = 0; i < data.length; i++)
              "${(i + 1).toString().padLeft(2, '0')} - ${data[i]["title"]}": false
          };
          subtopicIds = {
            for (var sub in data) "${(data.indexOf(sub) + 1).toString().padLeft(2, '0')} - ${sub["title"]}": sub["id"].toString()
          };
        });
      } else {
        print("❌ Failed to fetch subtopics: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching subtopics: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMaterialsAndQuizzes(String subtopicId) async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) return;

    try {
      // Fetch Materials
      final materialsResponse = await http.get(
        Uri.parse('$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/materials/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, String>> materialsList = [];
      if (materialsResponse.statusCode == 200) {
        List<dynamic> materialsData = jsonDecode(materialsResponse.body);
        materialsList = materialsData.map<Map<String, String>>((m) {
          return {
            "id": m["id"] ?? "N/A",
            "content": m["content"] ?? "",
            "type": m["type"] ?? "Unknown",
            "category": m["category"] ?? "Unknown",
            "optional_text": m["optional_text"] ?? "",
          };
        }).toList();
      } else {
        print("❌ Failed to fetch materials");
      }

      setState(() {
        subtopicMaterials[subtopicId] = materialsList;
      });

      // Fetch Quizzes
      final quizzesResponse = await http.get(
        Uri.parse('$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> quizzesList = [];
      if (quizzesResponse.statusCode == 200) {
        List<dynamic> quizzesData = jsonDecode(quizzesResponse.body);
        quizzesList = quizzesData.map((q) => {
          "id": q["id"]?.toString() ?? "N/A",
          "title": q["title"] ?? "Untitled Quiz",
          "difficulty": q["difficulty"] ?? "Unknown",
          "question_count": q["question_count"] ?? "0",
        }).toList();
      } else {
        print("❌ Failed to fetch quizzes");
      }

      setState(() {
        subtopicQuizzes[subtopicId] = quizzesList;
      });

    } catch (e) {
      print("❌ Error fetching materials/quizzes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: isExpanded.keys.map((section) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    section,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  trailing: Icon(
                    isExpanded[section]! ? Icons.expand_less : Icons.expand_more,
                    color: Colors.black,
                  ),
                  onTap: () async {
                    setState(() {
                      isExpanded[section] = !isExpanded[section]!;
                    });
                    if (isExpanded[section]! && subtopicIds.containsKey(section)) {
                      await fetchMaterialsAndQuizzes(subtopicIds[section]!);
                    }
                  },
                ),
                if (isExpanded[section]! && subtopicIds.containsKey(section))
                  _buildLessonsAndQuizzes(subtopicIds[section]!),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLessonsAndQuizzes(String subtopicId) {
    List<Map<String, dynamic>> materials = subtopicMaterials[subtopicId] ?? [];
    List<Map<String, dynamic>> quizzes = subtopicQuizzes[subtopicId] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          if (materials.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📚 Materials", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...materials.map((m) => _buildMaterialTile(m["id"], m["type"], m["category"], m["content"], subtopicId)),
              ],
            ),
          if (quizzes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("📝 Quizzes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...quizzes.map((q) => _buildQuizTile(q["id"], q["title"], q["difficulty"], q["question_count"])),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(String id, String type, String category, String content, String subtopicId) {
    return _buildTile(
      type,
      category,
      Icons.article,
          () {
        List<Map<String, String>> materials = subtopicMaterials[subtopicId]?.map<Map<String, String>>((m) {
          return {
            "type": m["type"].toString(),
            "content": m["content"].toString(),
          };
        }).toList() ?? [];

        if (materials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No materials available")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(materials: materials),
          ),
        );
      },
    );
  }

  void _downloadDocument(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading document...')),
    );
    // Open URL to let user download the document
  }

  Widget _buildQuizTile(String id, String title, String difficulty, String questionCount) {
    return _buildTile(
      title,
      "$difficulty • $questionCount Questions",
      Icons.quiz,
          () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LessonQuestionPage()),
        );
      },
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, color: AcademeTheme.appColor, size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: Text("$title\n$subtitle", style: const TextStyle(fontSize: 16, height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}
