import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class CourseProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrap entire content
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMePoints(context),
                ],
              ),
            ),
            _buildSectionTitle(
                L10n.getTranslatedText(context, 'Course Progress')),
            _buildCourseCard(
                L10n.getTranslatedText(context, 'Linear Algebra'),
                L10n.getTranslatedText(context, 'Mathematics'),
                80,
                L10n.getTranslatedText(context, '10 ${L10n.getTranslatedText(context, 'Modules')}')),
            _buildCourseCard(
                L10n.getTranslatedText(context, 'Organic Chemistry'),
                L10n.getTranslatedText(context, 'Chemistry'),
                25,
                L10n.getTranslatedText(context, '5 ${L10n.getTranslatedText(context, 'Modules')}')),
            _buildCourseCard(
                L10n.getTranslatedText(context, 'Linear Algebra'),
                L10n.getTranslatedText(context, 'Mathematics'),
                80,
                L10n.getTranslatedText(context, '10 ${L10n.getTranslatedText(context, 'Modules')}')),
            _buildQuizScores(context),
          ],
        ),
      ),
    );
  }

  // All other methods remain unchanged...
  Widget _buildMePoints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      width: width * 0.87,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: height * 0.02, horizontal: width * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.amber,
              size: 70,
            ),
            SizedBox(height: 10),
            Text(
              '420',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 5),
            RichText(
              text: TextSpan(
                text: L10n.getTranslatedText(context, 'My '),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: 'Me',
                    style: TextStyle(color: Colors.purple),
                  ),
                  TextSpan(text: L10n.getTranslatedText(context, ' Points')),
                ],
              ),
            ),
            SizedBox(height: 5),
            Text(
              L10n.getTranslatedText(context, 'Redeem your Points'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCourseCard(
      String title, String subject, int progress, String moduleCount) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildModuleIcon(),
                    SizedBox(width: 8),
                    Text(
                      moduleCount,
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildProgressIndicator(progress),
        ],
      ),
    );
  }

  Widget _buildModuleIcon() {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.menu_book, color: Colors.white, size: 20),
    );
  }

  Widget _buildProgressIndicator(int progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AcademeTheme.appColor),
            strokeWidth: 7,
          ),
        ),
        Text("$progress%",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuizScores(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuizScoreHeader(context),
            SizedBox(height: 10),
            _buildQuizScoreBars(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScoreHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.getTranslatedText(context, "Your quiz scores"),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "48%",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Text(
                  L10n.getTranslatedText(context, "Last 30 days"),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "+3%",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizScoreBars(BuildContext context) {
    return Column(
      children: [
        _buildBar(L10n.getTranslatedText(context, 'Maths'), 0.9),
        _buildBar(L10n.getTranslatedText(context, 'Chem'), 0.6),
        _buildBar(L10n.getTranslatedText(context, 'Phy'), 0.2),
        _buildBar(L10n.getTranslatedText(context,'English' ), 0.4),
      ],
    );
  }

  Widget _buildBar(String subject, double percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 30,
            child: Text(
              subject,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: const Color.fromARGB(147, 221, 218, 218),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AcademeTheme.appColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}