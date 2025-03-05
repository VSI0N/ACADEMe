import 'package:ACADEMe/home/admin_panel/topic.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/theme/custom_themes/course_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Map<String, dynamic>> courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? coursesString = prefs.getString('courses');
    if (coursesString != null) {
      setState(() {
        courses = List<Map<String, dynamic>>.from(json.decode(coursesString));
      });
    }
  }

  void _saveCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('courses', json.encode(courses));
  }

  void _addCourse() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController classController = TextEditingController();
        final TextEditingController durationController = TextEditingController();
        File? image;

        Future<void> pickImage() async {
          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() {
              image = File(pickedFile.path);
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    decoration: InputDecoration(labelText: "Class"),
                  ),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(labelText: "Duration"),
                  ),
                  SizedBox(height: 10),
                  image == null
                      ? Text("No Image Selected")
                      : Image.file(image!, height: 90),
                  TextButton(
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setDialogState(() {
                          image = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text("Select Image"),
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
                    setState(() {
                      courses.add({
                        "title": titleController.text,
                        "duration": durationController.text,
                        "class": classController.text,
                        "image": image?.path ?? "assets/images/default.png",
                      });
                      _saveCourses();
                    });
                    Navigator.pop(context);
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

  void _navigateToTopics(String courseTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicScreen(courseTitle: courseTitle),
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
        padding: EdgeInsets.all(10),
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
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(courses[index]['title']),
                    subtitle: Text("Class: ${courses[index]['class']}, Duration: ${courses[index]['duration']}"),
                    leading: courses[index]['image'] != null
                        ? Image.file(File(courses[index]['image']), height: 50, width: 50)
                        : Icon(Icons.book),
                    onTap: () => _navigateToTopics(courses[index]['title']),
                  );
                },
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
