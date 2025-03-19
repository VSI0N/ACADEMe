import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/flashcard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LessonsSection extends StatefulWidget {
  final String courseId;
  final String topicId;

  const LessonsSection(
      {super.key, required this.courseId, required this.topicId});

  @override
  _LessonsSectionState createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<LessonsSection> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  Map<String, bool> isExpanded = {};
  Map<String, String> subtopicIds = {};
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
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/'),
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
              "${(i + 1).toString().padLeft(2, '0')} - ${data[i]["title"]}":
                  false
          };
          subtopicIds = {
            for (var sub in data)
              "${(data.indexOf(sub) + 1).toString().padLeft(2, '0')} - ${sub["title"]}":
                  sub["id"].toString()
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
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/materials/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> materialsList = [];
      if (materialsResponse.statusCode == 200) {
        List<dynamic> materialsData = jsonDecode(materialsResponse.body);
        materialsList = materialsData.map<Map<String, dynamic>>((m) {
          return {
            "id": m["id"]?.toString() ?? "N/A",
            "content": m["content"] ?? "",
            "type": m["type"] ?? "Unknown",
            "category": m["category"] ?? "Unknown",
            "optional_text": m["optional_text"] ?? "",
          };
        }).toList();
      } else {
        print("❌ Failed to fetch materials: ${materialsResponse.statusCode}");
      }

      // Fetch Quizzes
      final quizzesResponse = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> quizzesList = [];
      if (quizzesResponse.statusCode == 200) {
        List<dynamic> quizzesData = jsonDecode(quizzesResponse.body);

        // Fetch questions for each quiz
        for (var quiz in quizzesData) {
          final quizId = quiz["id"]?.toString() ?? "N/A";
          final questionsResponse = await http.get(
            Uri.parse(
                '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=en'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (questionsResponse.statusCode == 200) {
            List<dynamic> questionsData = jsonDecode(questionsResponse.body);
            for (var question in questionsData) {
              quizzesList.add({
                "id": quizId,
                "title": quiz["title"] ?? "Untitled Quiz",
                "difficulty": quiz["difficulty"] ?? "Unknown",
                "question_count": questionsData.length.toString(),
                "question_text":
                    question["question_text"] ?? "No question text available",
                "options":
                    (question["options"] as List<dynamic>?)?.cast<String>() ??
                        ["No options available"],
                "correct_option": question["correct_option"] ?? 0,
              });
            }
          } else {
            print(
                "❌ Failed to fetch questions for quiz $quizId: ${questionsResponse.statusCode}");
          }
        }

        // Print quizzes data for debugging
        print("✅ Quizzes fetched successfully:");
        for (var quiz in quizzesList) {
          print("Quiz ID: ${quiz["id"]}");
          print("Title: ${quiz["title"]}");
          print("Difficulty: ${quiz["difficulty"]}");
          print("Question Count: ${quiz["question_count"]}");
          print("Question Text: ${quiz["question_text"]}");
          print("Options: ${quiz["options"]}");
          print("Correct Option: ${quiz["correct_option"]}");
          print("-----------------------------");
        }
      } else {
        print("❌ Failed to fetch quizzes: ${quizzesResponse.statusCode}");
      }

      setState(() {
        subtopicMaterials[subtopicId] = materialsList;
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        trailing: Icon(
                          isExpanded[section]!
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.black,
                        ),
                        onTap: () async {
                          setState(() {
                            isExpanded[section] = !isExpanded[section]!;
                          });
                          if (isExpanded[section]! &&
                              subtopicIds.containsKey(section)) {
                            await fetchMaterialsAndQuizzes(
                                subtopicIds[section]!);
                          }
                        },
                      ),
                      if (isExpanded[section]! &&
                          subtopicIds.containsKey(section))
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
                const Text("📚 Materials",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...materials.map((m) => _buildMaterialTile(m["id"], m["type"],
                    m["category"], m["content"], subtopicId)),
              ],
            ),
          if (quizzes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("📝 Quizzes",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...quizzes.map((q) => _buildQuizTile(q["id"], q["title"],
                    q["difficulty"], q["question_count"], subtopicId)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(String id, String type, String category,
      String content, String subtopicId) {
    return _buildTile(
      type,
      category,
      Icons.article,
      () {
        // Convert materials to the correct type
        List<Map<String, String>> materials =
            (subtopicMaterials[subtopicId] ?? []).map<Map<String, String>>((m) {
          return {
            "type": m["type"].toString(),
            "content": m["content"].toString(),
          };
        }).toList();

        if (materials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No materials available")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: materials, // Pass the converted list
              quizzes: subtopicQuizzes[subtopicId] ?? [],
              onQuizComplete: () {
                // Move to next subtopic after quizzes are completed
                _navigateToNextSubtopic(subtopicId);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTile(String id, String title, String difficulty,
      String questionCount, String subtopicId) {
    return _buildTile(
      title,
      "$difficulty • $questionCount Questions",
      Icons.quiz,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: [], // No materials for quizzes
              quizzes: subtopicQuizzes[subtopicId] ?? [],
              onQuizComplete: () {
                // Move to next subtopic after quizzes are completed
                _navigateToNextSubtopic(subtopicId);
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToNextSubtopic(String currentSubtopicId) {
    // Find the index of the current subtopic
    int currentIndex = subtopicIds.values.toList().indexOf(currentSubtopicId);

    // Check if there is a next subtopic
    if (currentIndex < subtopicIds.length - 1) {
      String nextSubtopicId = subtopicIds.values.toList()[currentIndex + 1];
      String nextSubtopicTitle = subtopicIds.keys.toList()[currentIndex + 1];

      // Fetch materials and quizzes for the next subtopic
      fetchMaterialsAndQuizzes(nextSubtopicId).then((_) {
        // Convert materials to the correct type
        List<Map<String, String>> nextMaterials =
            (subtopicMaterials[nextSubtopicId] ?? [])
                .map<Map<String, String>>((material) {
          return {
            "type": material["type"].toString(),
            "content": material["content"].toString(),
          };
        }).toList();

        // Open the next subtopic in the FlashCard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: nextMaterials, // Pass the converted list
              quizzes: subtopicQuizzes[nextSubtopicId] ?? [],
              onQuizComplete: () {
                // Move to next subtopic after quizzes are completed
                _navigateToNextSubtopic(nextSubtopicId);
              },
            ),
          ),
        );
      });
    } else {
      // No more subtopics, show a message or navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more subtopics available")),
      );
    }
  }

  Widget _buildTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
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
              child: Text("$title\n$subtitle",
                  style: const TextStyle(fontSize: 16, height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}
