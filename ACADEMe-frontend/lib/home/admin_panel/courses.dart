import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../academe_theme.dart';
import 'topic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Map<String, dynamic>> courses = [];
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      print("No access token found");
      return;
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        courses = data.map((item) => {
          "id": item["id"].toString(),
          "title": item["title"],
          "class_name": item["class_name"],
          "description": item["description"],
        }).toList();
      });
    } else {
      print("Failed to fetch courses: ${response.body}");
    }
  }

  void _addCourse() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController classController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text("Add Course"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Course Title"),
              ),
              TextField(
                controller: classController,
                decoration: InputDecoration(labelText: "Class Name"),
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
              onPressed: () async {
                String? token = await _storage.read(key: "access_token");
                if (token == null) {
                  print("No access token found");
                  return;
                }

                final response = await http.post(
                  Uri.parse('${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/courses/'),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },
                  body: json.encode({
                    "title": titleController.text,
                    "class_name": classController.text,
                    "description": descriptionController.text,
                  }),
                );

                if (response.statusCode == 200) {
                  _loadCourses();
                  Navigator.pop(context);
                } else {
                  print("Failed to add course: ${response.body}");
                }
              },
              child: Text("Add"),
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
        builder: (context) => TopicScreen(courseId: courseId, courseTitle: courseTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text("Admin Panel", style: TextStyle(color: Colors.white)),
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
                  "Course List",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: courses.map((course) => Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(course["title"]!),
                    subtitle: Text(course["description"]!),
                    onTap: () => _navigateToTopics(course["id"]!, course["title"]!),
                  ),
                )).toList(),
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
