import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../academe_theme.dart';

class TopicQuizScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String quizId;
  final String courseTitle;
  final String topicTitle;
  final String quizTitle;
  final String targetLanguage;

  const TopicQuizScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.quizId,
    required this.courseTitle,
    required this.topicTitle,
    required this.quizTitle,
    required this.targetLanguage,
  });

  @override
  TopicQuizScreenState createState() => TopicQuizScreenState();
}

class TopicQuizScreenState extends State<TopicQuizScreen> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/quizzes/${widget.quizId}/questions/?target_language=${widget.targetLanguage}");

    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":
              "application/json; charset=UTF-8", // Ensure UTF-8 encoding
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
        setState(() {
          questions = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch questions: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching questions: $e");
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController questionController =
            TextEditingController();
        List<TextEditingController> optionControllers = [
          TextEditingController(),
          TextEditingController(),
        ];
        int correctOption = 0;

        void addOption(setDialogState) {
          if (optionControllers.length < 4) {
            setDialogState(() {
              optionControllers.add(TextEditingController());
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Question"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(labelText: "Question"),
                    ),
                    ...List.generate(optionControllers.length, (index) {
                      return TextField(
                        controller: optionControllers[index],
                        decoration:
                            InputDecoration(labelText: "Option ${index + 1}"),
                      );
                    }),
                    if (optionControllers.length < 4)
                      TextButton(
                        onPressed: () => addOption(setDialogState),
                        child: Text("Add Another Option"),
                      ),
                    DropdownButtonFormField<int>(
                      value: correctOption,
                      items: List.generate(optionControllers.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text("Correct Option: ${index + 1}"),
                        );
                      }),
                      onChanged: (value) {
                        setDialogState(() {
                          correctOption = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (questionController.text.isNotEmpty &&
                        optionControllers.every(
                            (controller) => controller.text.isNotEmpty)) {
                      final success = await _submitQuestion(
                        question: questionController.text,
                        options: optionControllers.map((c) => c.text).toList(),
                        correctOption: correctOption,
                      );
                      if (!context.mounted) {
                        return; // Now properly wrapped in a block
                      }

                      if (success) {
                        Navigator.pop(context);
                        _fetchQuestions();
                      }
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitQuestion({
    required String question,
    required List<String> options,
    required int correctOption,
  }) async {
    final url = Uri.parse(
        "${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/${widget.courseId}/topics/${widget.topicId}/quizzes/${widget.quizId}/questions/");

    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return false;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":
              "application/json; charset=UTF-8", // Ensure UTF-8 encoding
        },
        body: json.encode({
          "question_text": question,
          "options": options,
          "correct_option": correctOption,
          "target_language": widget.targetLanguage, // Include target_language
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
        debugPrint("✅ Question added successfully: ${responseData["message"]}");
        return true;
      } else {
        _showError("Failed to add question: ${response.body}");
        return false;
      }
    } catch (e) {
      _showError("Error submitting question: $e");
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > ${widget.topicTitle} > ${widget.quizTitle}",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : questions.isEmpty
                ? Center(child: Text("No questions added yet."))
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${index + 1}. ${question["question_text"]}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Column(
                                children: (question["options"] as List<dynamic>)
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  String optionText = entry.value;

                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: question["correct_option"] == idx
                                          ? Colors.green.withAlpha(20)
                                          : Colors.grey.withAlpha(10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text("${idx + 1}) ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Expanded(child: Text(optionText)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        backgroundColor: AcademeTheme.appColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
