import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../academe_theme.dart';
import '../../localization/l10n.dart';
import 'topic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  CourseManagementScreenState createState() => CourseManagementScreenState();
}

class CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Map<String, dynamic>> courses = [];
  final _storage = FlutterSecureStorage();
  String? _targetLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndCourses();
  }

  Future<void> _loadLanguageAndCourses() async {
    // Fetch the app's language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _targetLanguage =
        prefs.getString('language') ?? 'en'; // Default to 'en' if not set

    // Load courses after fetching the language
    _loadCourses();
  }

  void _loadCourses() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      debugPrint("No access token found");
      return;
    }

    final response = await http.get(
      Uri.parse(
          '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/?target_language=$_targetLanguage'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type":
            "application/json; charset=UTF-8", // Ensure UTF-8 encoding
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data =
          json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
      setState(() {
        courses = data
            .map((item) => {
                  "id": item["id"].toString(),
                  "title": item["title"],
                  "class_name": item["class_name"],
                  "description": item["description"],
                })
            .toList();
      });
    } else {
      debugPrint("Failed to fetch courses: ${response.body}");
    }
  }

  void _addCourse() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController classController = TextEditingController();
        final TextEditingController descriptionController =
            TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Course')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Course Title')),
              ),
              TextField(
                controller: classController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Class Name')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                String? token = await _storage.read(key: "access_token");
                if (token == null) {
                  debugPrint("No access token found");
                  return;
                }

                final response = await http.post(
                  Uri.parse(
                      '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/'),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type":
                        "application/json; charset=UTF-8", // Ensure UTF-8 encoding
                  },
                  body: json.encode({
                    "title": titleController.text,
                    "class_name": classController.text,
                    "description": descriptionController.text,
                  }),
                );

                if (!context.mounted) {
                  return; // Now properly wrapped in a block
                }

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(context);
                  setState(() {
                    _loadCourses();
                  });
                } else {
                  debugPrint("Failed to add course: ${response.body}");
                }
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTopics(String courseId, String courseTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TopicScreen(courseId: courseId, courseTitle: courseTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(L10n.getTranslatedText(context, 'Admin Panel'),
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
                  L10n.getTranslatedText(context, 'Course List'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: courses.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AcademeTheme.appColor, // Custom color
                      ),
                    )
                  : ListView(
                      children: courses
                          .map((course) => Card(
                                margin: EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(course["title"]!),
                                  subtitle: Text(course["description"]!),
                                  onTap: () => _navigateToTopics(
                                      course["id"]!, course["title"]!),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        backgroundColor: AcademeTheme.appColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
