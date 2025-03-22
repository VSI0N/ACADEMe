import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/flashcard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonsSection extends StatefulWidget {
  final String courseId;
  final String topicId;

  const LessonsSection({
    super.key,
    required this.courseId,
    required this.topicId,
  });

  @override
  _LessonsSectionState createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<LessonsSection> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  Map<String, bool> isExpanded = {};
  Map<String, String> subtopicIds = {};
  Map<String, List<Map<String, dynamic>>> subtopicMaterials = {};
  Map<String, List<Map<String, dynamic>>> subtopicQuizzes = {};
  Map<String, bool> materialCompletionStatus = {};
  Map<String, bool> quizCompletionStatus = {};
  bool isLoading = true;
  bool isResume = false;

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

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

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

        // Fetch progress list and materials/quizzes for all subtopics
        await _fetchProgressList();
        for (var subtopicId in subtopicIds.values) {
          await fetchMaterialsAndQuizzes(subtopicId);
        }
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

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
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
        final String quizzesBody = utf8.decode(quizzesResponse.bodyBytes);
        List<dynamic> quizzesData = jsonDecode(quizzesBody);

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

  Future<void> _fetchProgressList() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      return;
    }

    const targetLanguage = 'en'; // Hardcoded to English

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/progress/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final List<Map<String, dynamic>> progressList =
        List<Map<String, dynamic>>.from(data["progress"]);

        // Update completion status for materials and quizzes
        for (var progress in progressList) {
          if (progress["material_id"] != null) {
            materialCompletionStatus[progress["material_id"]] = true;
          }
          if (progress["quiz_id"] != null) {
            quizCompletionStatus[progress["quiz_id"]] = true;
          }
        }
      } else {
        print("❌ Failed to fetch progress: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: Column(
              children: [
                ...isExpanded.keys.map((section) {
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
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () {
                  if (subtopicIds.isNotEmpty) {
                    final firstSubtopicId = subtopicIds.values.first;
                    fetchMaterialsAndQuizzes(firstSubtopicId).then((_) {
                      int firstUntickedIndex = 0;
                      final materials = subtopicMaterials[firstSubtopicId] ?? [];
                      final quizzes = subtopicQuizzes[firstSubtopicId] ?? [];

                      // Prioritize materials over quizzes
                      for (int i = 0; i < materials.length; i++) {
                        if (!(materialCompletionStatus[materials[i]["id"]] ??
                            false)) {
                          firstUntickedIndex = i;
                          break;
                        }
                      }

                      // If no incomplete materials are found, check quizzes
                      if (firstUntickedIndex == 0 && materials.isNotEmpty) {
                        for (int i = 0; i < quizzes.length; i++) {
                          if (!(quizCompletionStatus[quizzes[i]["id"]] ?? false)) {
                            firstUntickedIndex = materials.length + i;
                            break;
                          }
                        }
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashCard(
                            materials: materials.map<Map<String, String>>((m) {
                              return {
                                "type": m["type"].toString(),
                                "content": m["content"].toString(),
                              };
                            }).toList(),
                            quizzes: quizzes,
                            onQuizComplete: () {
                              _navigateToNextSubtopic(firstSubtopicId);
                            },
                            initialIndex: firstUntickedIndex,
                            courseId: widget.courseId,
                            topicId: widget.topicId,
                            subtopicId: firstSubtopicId,
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
                child: Text(
                  isResume ? "Resume" : "Start Course",
                  style: const TextStyle(
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
                    materials.indexOf(m))),
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
                    quizzes.indexOf(q))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(String id, String type, String category,
      String content, String subtopicId, int index) {
    final isCompleted = materialCompletionStatus[id] ?? false;

    return _buildTile(
      type,
      category,
      isCompleted ? Icons.check_circle : null, // Only show tick icon if completed
      false, // No outline
          () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: (subtopicMaterials[subtopicId] ?? [])
                  .map<Map<String, String>>((m) {
                return {
                  "type": m["type"].toString(),
                  "content": m["content"].toString(),
                };
              }).toList(),
              quizzes: subtopicQuizzes[subtopicId] ?? [],
              onQuizComplete: () {
                _navigateToNextSubtopic(subtopicId);
              },
              initialIndex: index,
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: subtopicId,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTile(String id, String title, String difficulty,
      String questionCount, String subtopicId, int index) {
    final isCompleted = quizCompletionStatus[id] ?? false;

    return _buildTile(
      title,
      "$difficulty • $questionCount Questions",
      isCompleted ? Icons.check_circle : null, // Only show tick icon if completed
      false, // No outline
          () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: [],
              quizzes: subtopicQuizzes[subtopicId] ?? [],
              onQuizComplete: () {
                _navigateToNextSubtopic(subtopicId);
              },
              initialIndex: index,
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: subtopicId,
            ),
          ),
        );
      },
    );
  }

  void _navigateToNextSubtopic(String currentSubtopicId) {
    int currentIndex = subtopicIds.values.toList().indexOf(currentSubtopicId);

    if (currentIndex < subtopicIds.length - 1) {
      String nextSubtopicId = subtopicIds.values.toList()[currentIndex + 1];
      fetchMaterialsAndQuizzes(nextSubtopicId).then((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: (subtopicMaterials[nextSubtopicId] ?? [])
                  .map<Map<String, String>>((m) {
                return {
                  "type": m["type"].toString(),
                  "content": m["content"].toString(),
                };
              }).toList(),
              quizzes: subtopicQuizzes[nextSubtopicId] ?? [],
              onQuizComplete: () {
                _navigateToNextSubtopic(nextSubtopicId);
              },
              initialIndex: 0,
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: nextSubtopicId,
            ),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No more subtopics available")),
      );
    }
  }

  Widget _buildTile(
      String title, String subtitle, IconData? icon, bool hasOutline, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: hasOutline
              ? Border.all(color: Colors.deepPurple, width: 1)
              : null,
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
                  title.split(" ")[0],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Text(
                  title.substring(title.indexOf(" ") + 1),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (icon != null)
              Icon(
                icon,
                color: icon == Icons.check_circle ? Colors.green : Colors.deepPurple,
              ),
          ],
        ),
      ),
    );
  }
}