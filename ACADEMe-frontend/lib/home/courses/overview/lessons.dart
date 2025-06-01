import 'dart:convert';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/courses/overview/flashcard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/localization/language_provider.dart';

import '../report.dart';

class LessonsSection extends StatefulWidget {
  final String courseId;
  final String topicId;

  const LessonsSection({
    super.key,
    required this.courseId,
    required this.topicId,
  });

  @override
  LessonsSectionState createState() => LessonsSectionState();
}

class LessonsSectionState extends State<LessonsSection> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  Map<String, bool> isExpanded = {};
  Map<String, String> subtopicIds = {};
  Map<String, List<Map<String, dynamic>>> subtopicMaterials = {};
  Map<String, List<Map<String, dynamic>>> subtopicQuizzes = {};
  Map<String, bool> subtopicLoading = {};
  bool isLoading = true;
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();
    fetchSubtopics();
  }

  IconData _getIconForContentType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'text':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'document':
        return Icons.description;
      default:
        return Icons.article; // Default icon for unknown types
    }
  }

  Future<void> fetchSubtopics() async {
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }

    // Get the target language from the app's language provider
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage&order_by=created_at'),
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
        debugPrint("❌ Failed to fetch subtopics: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching subtopics: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMaterialsAndQuizzes(String subtopicId) async {
    setState(() {
      subtopicLoading[subtopicId] = true;
    });

    String? token = await storage.read(key: 'access_token');
    if (token == null) return;
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }

    // Get the target language from the app's language provider
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      // Fetch Materials
      final materialsResponse = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/materials/?target_language=$targetLanguage&order_by=created_at'),
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
            "created_at": m["created_at"] ?? "",
          };
        }).toList();
      } else {
        debugPrint(
            "❌ Failed to fetch materials: ${materialsResponse.statusCode}");
      }

      // Fetch Quizzes
      final quizzesResponse = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/?target_language=$targetLanguage&order_by=created_at'),
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
                '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$targetLanguage&order_by=created_at'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          );

          if (questionsResponse.statusCode == 200) {
            // Decode the response body using UTF-8
            final String questionsBody =
            utf8.decode(questionsResponse.bodyBytes);
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
                "created_at": quiz["created_at"] ?? "",
              });
            }
          } else {
            debugPrint(
                "❌ Failed to fetch questions for quiz $quizId: ${questionsResponse.statusCode}");
          }
        }

        // Print quizzes data for debugging
        debugPrint("✅ Quizzes fetched successfully:");
        for (var quiz in quizzesList) {
          debugPrint("Quiz ID: ${quiz["id"]}");
          debugPrint("Title: ${quiz["title"]}");
          debugPrint("Difficulty: ${quiz["difficulty"]}");
          debugPrint("Question Count: ${quiz["question_count"]}");
          debugPrint("Question Text: ${quiz["question_text"]}");
          debugPrint("Options: ${quiz["options"]}");
          debugPrint("Correct Option: ${quiz["correct_option"]}");
          debugPrint("Created At: ${quiz["created_at"]}");
          debugPrint("-----------------------------");
        }
      } else {
        debugPrint("❌ Failed to fetch quizzes: ${quizzesResponse.statusCode}");
      }

      setState(() {
        subtopicMaterials[subtopicId] = materialsList;
        subtopicQuizzes[subtopicId] = quizzesList;
        subtopicLoading[subtopicId] = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching materials/quizzes: $e");
    } finally {
      setState(() {
        subtopicLoading[subtopicId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100), // Added bottom padding
            child: Column(
              children: [
                // Existing content
                ...isExpanded.keys.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          section,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
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
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: isNavigating
              ? null
              : () {
            if (subtopicIds.isNotEmpty) {
              setState(() => isNavigating = true);
              final firstSubtopicId = subtopicIds.values.first;
              final firstSubtopicTitle = subtopicIds.keys.first;
              fetchMaterialsAndQuizzes(firstSubtopicId).then((_) {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashCard(
                      materials:
                      (subtopicMaterials[firstSubtopicId] ?? [])
                          .map<Map<String, String>>((material) {
                        return {
                          "id": material["id"]?.toString() ?? "",
                          "type": material["type"]?.toString() ?? "",
                          "content":
                          material["content"]?.toString() ?? "",
                        };
                      }).toList(),
                      quizzes: subtopicQuizzes[firstSubtopicId] ?? [],
                      onQuizComplete: () =>
                          _navigateToNextSubtopic(firstSubtopicId),
                      initialIndex: 0,
                      courseId: widget.courseId,
                      topicId: widget.topicId,
                      subtopicId: firstSubtopicId,
                      subtopicTitle: firstSubtopicTitle,
                    ),
                  ),
                ).then((_) {
                  if (mounted) setState(() => isNavigating = false);
                });
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
            isNavigating
                ? L10n.getTranslatedText(context, 'Start Course')
                : L10n.getTranslatedText(context, 'Start Course'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsAndQuizzes(String subtopicId) {
    if (subtopicLoading[subtopicId] == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
              color: AcademeTheme.appColor),
        ),
      );
    }

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
    // Get the title from subtopicIds map
    String subtopicTitle = subtopicIds.entries
        .firstWhere((entry) => entry.value == subtopicId)
        .key;

    // Localize the type while keeping the original for icon determination
    String localizedType = type.toLowerCase() == 'video'
        ? L10n.getTranslatedText(context, 'Video')
        : type.toLowerCase() == 'text'
        ? L10n.getTranslatedText(context, 'Text')
        : type.toLowerCase() == 'quiz'
        ? L10n.getTranslatedText(context, 'Quiz')
        : type.toLowerCase() == 'document'
        ? L10n.getTranslatedText(context, 'Document')
        : L10n.getTranslatedText(context, 'Material');

    return _buildTile(
      localizedType, // Use localized type for display
      category,
      _getIconForContentType(type), // Keep original type for icon
          () {
        List<Map<String, String>> materials =
        (subtopicMaterials[subtopicId] ?? []).map<Map<String, String>>((m) {
          return {
            "id": m["id"]?.toString() ?? "",
            "type": m["type"]?.toString() ?? "",
            "content": m["content"]?.toString() ?? "",
          };
        }).toList();

        if (materials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    L10n.getTranslatedText(context, 'No materials available'))),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: materials,
              quizzes: subtopicQuizzes[subtopicId] ?? [],
              onQuizComplete: () => _navigateToNextSubtopic(subtopicId),
              initialIndex: index,
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: subtopicId,
              subtopicTitle: subtopicTitle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTile(String id, String title, String difficulty,
      String questionCount, String subtopicId, int index) {
    // Get the title from subtopicIds map
    String subtopicTitle = subtopicIds.entries
        .firstWhere((entry) => entry.value == subtopicId)
        .key;

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
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: subtopicId,
              subtopicTitle: subtopicTitle, // Pass the title
            ),
          ),
        );
      },
    );
  }

  void _navigateToNextSubtopic(String currentSubtopicId) {
    int currentIndex = subtopicIds.values.toList().indexOf(currentSubtopicId);
    // In _navigateToNextSubtopic method:
    if (currentIndex < subtopicIds.length - 1) {
      String nextSubtopicId = subtopicIds.values.toList()[currentIndex + 1];
      String nextSubtopicTitle = subtopicIds.keys.toList()[currentIndex + 1];

      fetchMaterialsAndQuizzes(nextSubtopicId).then((_) {
        List<Map<String, String>> nextMaterials =
        (subtopicMaterials[nextSubtopicId] ?? [])
            .map<Map<String, String>>((material) {
          return {
            "id": material["id"]?.toString() ?? "",
            "type": material["type"]?.toString() ?? "",
            "content": material["content"]?.toString() ?? "",
          };
        }).toList();

        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCard(
              materials: nextMaterials,
              quizzes: subtopicQuizzes[nextSubtopicId] ?? [],
              onQuizComplete: () => _navigateToNextSubtopic(nextSubtopicId),
              initialIndex: 0,
              courseId: widget.courseId,
              topicId: widget.topicId,
              subtopicId: nextSubtopicId,
              subtopicTitle: nextSubtopicTitle, // Pass the new title
            ),
          ),
        );
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TestReportScreen()),
      );
    }
  }

  Widget _buildTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    // Capitalize the first letter of the title
    String capitalizedTitle = title.substring(title.indexOf(" ") + 1);
    if (capitalizedTitle.isNotEmpty) {
      capitalizedTitle =
          capitalizedTitle[0].toUpperCase() + capitalizedTitle.substring(1);
    }

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
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      capitalizedTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
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