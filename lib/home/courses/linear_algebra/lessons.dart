import 'package:flutter/material.dart';
import '../../../academe_theme.dart';

class LessonsSection extends StatefulWidget {
  @override
  _LessonsSectionState createState() => _LessonsSectionState();
}

class _LessonsSectionState extends State<LessonsSection> {
  Map<String, bool> isExpanded = {
    "I - Introduction": true,
    "II - Plan for your UX Research": false,
    "III - Design your UX": false,
    "IV - Articulate findings": false,
    "V - Assessment": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
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
                      if (isExpanded[section]!) _buildLessonItems(section),
                    ],
                  );
                }).toList(),
              ),
            ),
            _buildResumeButton(),
            SizedBox(height: 15,)
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItems(String section) {
    if (section == "I - Introduction") {
      return Column(
        children: [
          _buildLessonTile("01", "Amet adipiscing consectetur", "01:23 mins", true),
          _buildLessonTile("02", "Culpa est incididunt enim id adi", "01:23 mins", false, hasPlayIcon: true),
          _buildQuizTile("03", "Quiz Time"),
        ],
      );
    }
    return SizedBox();
  }

  Widget _buildLessonTile(String number, String title, String duration, bool isCompleted, {bool hasPlayIcon = false}) {
    return ListTile(
      leading: Text(number, style: TextStyle(fontWeight: FontWeight.bold)),
      title: Text(title),
      subtitle: Text(duration, style: TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: isCompleted
          ? Icon(Icons.check_circle, color: AcademeTheme.appColor)
          : (hasPlayIcon ? Icon(Icons.play_circle_outline, color: AcademeTheme.appColor) : null),
    );
  }

  Widget _buildQuizTile(String number, String title) {
    return ListTile(
      leading: Text(number, style: TextStyle(fontWeight: FontWeight.bold)),
      title: Text(title),
      trailing: Icon(Icons.edit, color: AcademeTheme.appColor),
    );
  }

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
        child: Center(child: Text("Resume", style: TextStyle(fontSize: 16, color: Colors.white))),
      ),
    );
  }
}
