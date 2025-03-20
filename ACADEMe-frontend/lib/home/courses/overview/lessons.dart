import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/flashcard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/localization/language_provider.dart';

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

    // Get the target language from the app's language provider
    final targetLanguage =
        Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Decode the response body using UTF-8
        final String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = jsonDecode(responseBody);

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

    // Get the target language from the app's language provider
    final targetLanguage =
        Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

    try {
      // Fetch Materials
      final materialsResponse = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/materials/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      List<Map<String, dynamic>> materialsList = [];
      if (materialsResponse.statusCode == 200) {
        // Decode the response body using UTF-8
        final String materialsBody = utf8.decode(materialsResponse.bodyBytes);
        List<dynamic> materialsData = jsonDecode(materialsBody);
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
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      List<Map<String, dynamic>> quizzesList = [];
      if (quizzesResponse.statusCode == 200) {
        // Decode the response body using UTF-8
        final String quizzesBody = utf8.decode(quizzesResponse.bodyBytes);
        List<dynamic> quizzesData = jsonDecode(quizzesBody);

        // Fetch questions for each quiz
        for (var quiz in quizzesData) {
          final quizId = quiz["id"]?.toString() ?? "N/A";
          final questionsResponse = await http.get(
            Uri.parse(
                '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$targetLanguage'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          );

          if (questionsResponse.statusCode == 200) {
            // Decode the response body using UTF-8
            final String questionsBody = utf8.decode(questionsResponse.bodyBytes);
            List<dynamic> questionsData = jsonDecode(questionsBody);
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
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
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
                            fontWeight: FontWeight.bold, fontSize: 17),
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
          // **🔹 Start Course Button**
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the first subtopic
                  if (subtopicIds.isNotEmpty) {
                    final firstSubtopicId = subtopicIds.values.first;
                    fetchMaterialsAndQuizzes(firstSubtopicId).then((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashCard(
                            materials: (subtopicMaterials[firstSubtopicId] ?? []).map<Map<String, String>>((material) {
                              return {
                                "type": material["type"].toString(),
                                "content": material["content"].toString(),
                              };
                            }).toList(), // Convert to List<Map<String, String>>
                            quizzes: subtopicQuizzes[firstSubtopicId] ?? [],
                            onQuizComplete: () {
                              // Move to next subtopic after quizzes are completed
                              _navigateToNextSubtopic(firstSubtopicId);
                            },
                            initialIndex: 0, // Start from the first item
                          ),
                        ),
                      );
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcademeTheme.appColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Start Course",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                ...materials.map((m) => _buildMaterialTile(
                    m["id"],
                    m["type"],
                    m["category"],
                    m["content"],
                    subtopicId,
                    materials.indexOf(m))), // Pass the index
              ],
            ),
          if (quizzes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...quizzes.map((q) => _buildQuizTile(
                    q["id"],
                    q["title"],
                    q["difficulty"],
                    q["question_count"],
                    subtopicId,
                    quizzes.indexOf(q))), // Pass the index
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(String id, String type, String category,
      String content, String subtopicId, int index) {
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
              initialIndex: index, // Start from the clicked material
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTile(String id, String title, String difficulty,
      String questionCount, String subtopicId, int index) {
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
              initialIndex: index, // Start from the clicked quiz
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
              initialIndex: 0, // Start from the first item
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
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title.split(" ")[0], // Extract number (e.g., "01", "02")
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Text(
                  title.substring(title.indexOf(" ") + 1), // Extract text after number
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }
}