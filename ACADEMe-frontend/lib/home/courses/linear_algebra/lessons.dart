import 'package:ACADEMe/home/courses/linear_algebra/quiz.dart';
import 'package:flutter/material.dart';
import '../../../academe_theme.dart';
// import '../../pages/my_courses.dart';
import 'package:ACADEMe/home/pages/home_view.dart';
import 'flashcard.dart';

class LessonsSection extends StatefulWidget {
  @override
  _LessonsSectionState createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<LessonsSection> {
  Map<String, bool> isExpanded = {
    "I - Introduction": false,
    "II - Plan for your UX Research": false,
    "III - Design your UX": false,
    "IV - Articulate findings": false,
    "V - Assessment": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                children: isExpanded.keys.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          section,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        trailing: Icon(
                          isExpanded[section]! ? Icons.expand_less : Icons.expand_more,
                          color: Colors.black,
                        ),
                        onTap: () {
                          setState(() {
                            isExpanded[section] = !isExpanded[section]!;
                          });
                        },
                      ),
                      if (isExpanded[section]!) _buildLessonsList(),
                    ],
                  );
                }).toList(),
              ),
              _buildResumeButton(),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  /// **List of Lessons & Quiz (Each inside its own Container)**
  Widget _buildLessonsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26), // Added horizontal padding
      child: Column(
        children: [
          _buildLessonTile("01", "Amet adipiscing consectetur", "01:23 mins", true, navigateTo: flashCard()),
          _buildLessonTile("02", "Culpa est incididunt enim id adi", "01:23 mins", false, hasPlayIcon: true),
          _buildQuizTile("03", "Quiz Time"),
        ],
      ),
    );
  }

  /// **Lesson Tile (Each inside its own Container)**
  Widget _buildLessonTile(String number, String title, String duration, bool isCompleted, {bool hasPlayIcon = false, Widget? navigateTo}) {
    return GestureDetector(
      onTap: () {
        if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased horizontal padding
        margin: EdgeInsets.symmetric(vertical: 5), // Space between tiles
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 15),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: "$title\n",
                  style: TextStyle(fontSize: 16, height: 1.2),
                  children: [
                    TextSpan(
                      text: duration,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (isCompleted)
              Icon(Icons.check_circle, color: AcademeTheme.appColor, size: 20)
            else if (hasPlayIcon)
              Icon(Icons.play_circle_outline, color: AcademeTheme.appColor, size: 22),
          ],
        ),
      ),
    );
  }

  /// **Quiz Tile (Each inside its own Container)**
  Widget _buildQuizTile(String number, String title) {
    return GestureDetector(
      onTap: () {
        print("Tapped on Quiz: $title");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased horizontal padding
        margin: EdgeInsets.symmetric(vertical: 5), // Space between tiles
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 15),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 16)),
            ),
            Icon(Icons.edit, color: AcademeTheme.appColor, size: 22),
          ],
        ),
      ),
    );
  }

  /// **Resume Course Button**
  Widget _buildResumeButton() {
    return Padding(
      padding: EdgeInsets.only(top: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AcademeTheme.appColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {},
        child: Center(child: Text("Start Course", style: TextStyle(fontSize: 16, color: Colors.white))),
      ),
    );
  }
}