import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/motivation_popup.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProgressScreen extends StatelessWidget {
  String getLetterGrade(BuildContext context, double score) {
    if (score >= 90) return "A++";
    if (score >= 80) return "A+";
    if (score >= 70) return "A";
    if (score >= 60) return "B+";
    if (score >= 50) return "B";
    if (score >= 40) return "C";
    if (score == 0) {
      return "${L10n.getTranslatedText(context, 'Start your')}\n${L10n.getTranslatedText(context, 'Journey')}";
    }
    return "F"; // If below 40
  }


  int totalCourses = 0;
  // Fetch courses from the backend

  Future<List<dynamic>> _fetchCourses() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token =
        await const FlutterSecureStorage().read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse("$backendUrl/api/courses/?target_language=en"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data; // Return full list of courses
    } else {
      throw Exception("❌ Failed to fetch courses: ${response.statusCode}");
    }
  }

  Future<double> _fetchOverallGrade() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token =
        await const FlutterSecureStorage().read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse("$backendUrl/api/progress-visuals/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final Map<String, dynamic> visualData = data['visual_data'];

      if (visualData.isNotEmpty) {
        final String firstKey =
            visualData.keys.first; // Get the first course ID dynamically
        final double avgScore = (visualData[firstKey]['avg_score'] ?? 0)
            .toDouble(); // ✅ Keep as double
        return avgScore; // ✅ No need to round, use double
      }
      return 0.0;
    } else {
      throw Exception(
          "❌ Failed to fetch overall grade: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AcademeTheme.appColor,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes back button
          title: Text(
            L10n.getTranslatedText(context, 'My Progress'),
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          backgroundColor: AcademeTheme.appColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 16.0), // Add top padding
          child: Column(
            children: [
              // Expanded container to use full screen height
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(26),
                    ),
                    border: Border.all(
                        color: const Color.fromARGB(0, 158, 158, 158),
                        width: 1),
                  ),
                  child: Column(
                    children: [
                      // Graph section with margin
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        child: _buildStudyTimeCard(context),
                      ),
                      const SizedBox(height: 8),
                      // Container wrapping both TabBar & TabBarView
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(73, 136, 189, 233),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                            ),
                            border: Border.all(
                                color: const Color.fromARGB(25, 16, 16, 16),
                                width: 1),
                          ),
                          child: Column(
                            children: [
                              // Tab bar container
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                child: TabBar(
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.blueAccent,
                                  dividerColor: Colors
                                      .transparent, // Removes the black line under tabs
                                  indicator: BoxDecoration(
                                    color: AcademeTheme.appColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  indicatorWeight:
                                      0, // Remove default indicator thickness
                                  indicatorPadding:
                                      EdgeInsets.zero, // Remove default padding
                                  tabs: [
                                    Tab(
                                      child: SizedBox(
                                        width: 100, // Control the tab width
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Summary'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: SizedBox(
                                        width: 100, // Control the tab width
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Progress'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: SizedBox(
                                        width: 100, // Control the tab width
                                        child: Center(
                                          child: Text(
                                            L10n.getTranslatedText(
                                                context, 'Activity'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Expanded container for TabBarView
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(26),
                                      topRight: Radius.circular(26),
                                    ),
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            26, 16, 16, 16),
                                        width: 1),
                                  ),
                                  child: TabBarView(
                                    children: [
                                      SingleChildScrollView(
                                        child: _buildSummarySection(context),
                                      ),
                                      SingleChildScrollView(
                                        child: _buildCourseProgress(context),
                                      ),
                                      SingleChildScrollView(
                                        child: _buildActivitySection(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyTimeCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap( // Wrap ensures proper line breaking
            spacing: 8, // Space between items
            runSpacing: 8, // Space between lines when wrapped
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                L10n.getTranslatedText(context, 'Average Study Time'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white24, // Slightly transparent white
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'This Week'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8), // Added space if text wraps
          Text(
            "2h 45m",
            style: TextStyle(
              color: const Color.fromARGB(193, 255, 255, 255),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(height: 170, width: double.infinity, child: _buildBarChart()), // Ensure full width
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10, // Set the maximum Y-axis value to 10 for scaling
        backgroundColor: Colors.transparent,
        barGroups: [
          for (int i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: (2 + i).toDouble(), // Keep original data values
                  color: Colors.yellow,
                  width: 22, // Increase width to make bars wider
                  borderRadius: BorderRadius.zero, // Remove curviness
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  ["M", "T", "W", "T", "F", "S", "S"][value.toInt()],
                  style: TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withAlpha(20), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_fetchCourses(), _fetchOverallGrade()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("❌ Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No courses available."));
        }

        List<dynamic> courses =
            snapshot.data![0] as List<dynamic>; // ✅ Courses data
        double overallGrade = snapshot.data![1] as double; // ✅ Avg score

        int totalCourses = courses.length; // ✅ Get total courses
        String letterGrade =
            getLetterGrade(context,overallGrade); // ✅ Convert to letter grade
        double progressValue =
            overallGrade / 100; // ✅ Normalize for progress bar

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: const Color.fromARGB(27, 158, 158, 158)),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: _buildSummaryItem(
                            L10n.getTranslatedText(context, 'Total Courses'),
                            totalCourses.toString()), // ✅ Display total courses
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: const Color.fromARGB(27, 158, 158, 158)),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: _buildSummaryItem(
                            L10n.getTranslatedText(context, 'Completed'), "2"),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// ✅ "Overall Grade" Card (Using Combined FutureBuilder)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color.fromARGB(27, 158, 158, 158)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildSummaryItem(
                    L10n.getTranslatedText(context, 'Overall Grade'),
                    overallGrade
                        .toStringAsFixed(2), // ✅ Fix function call issue
                    isCircular: true,
                    letterGrade: letterGrade, // ✅ Dynamic letter grade
                    progressValue: progressValue, // ✅ Dynamic progress bar
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _buildMotivationCard(context, overallGrade),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMotivationCard(BuildContext context, double score) {
    String getMotivationMessage(double score) {
      if (score >= 90) return L10n.getTranslatedText(context, 'Outstanding! Keep shining!');
      if (score >= 80) return L10n.getTranslatedText(context,'Excellent job! Almost perfect!');
      if (score >= 70) return L10n.getTranslatedText(context,'Great work! Keep pushing!');
      if (score >= 60) return L10n.getTranslatedText(context,'Good effort! You can do better!');
      if (score >= 50) return L10n.getTranslatedText(context,'Keep trying! Progress is progress!');
      if (score >= 40) return L10n.getTranslatedText(context,'Don’t give up! Keep learning!');
      if(score == 0) return L10n.getTranslatedText(context,'It\'s time to start your journey!');
      return L10n.getTranslatedText(context, 'Failure is the first step to success!');
    }

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const MotivationPopup(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getMotivationMessage(score), // Dynamic message based on score
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  L10n.getTranslatedText(context, 'Learn about your weak points'), // Keeping this same
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            ),

            const Icon(Icons.arrow_forward_ios_rounded),
          ],
        ),
        )

      ),
    );
  }

  Widget _buildSummaryItem(String title, String value,
      {bool isCircular = false,
      String letterGrade = "",
      double progressValue = 0.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          isCircular
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value, // ✅ Shows numeric grade
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AcademeTheme.appColor,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.grey[300],
                            color: AcademeTheme.appColor,
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          letterGrade, // ✅ Dynamic letter grade
                          style: TextStyle(
                            fontSize: letterGrade.length == 1 ? 28 : 12, // 🎯 Condition added
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(value,
                  style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor)),
        ],
      ),
    );
  }

  Widget _buildCourseProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 16.0), // Top and bottom padding outside the entire column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0), // Left and right padding inside the Row
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .center, // This centers the widget horizontally
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
    );
  }

  Widget _buildMePoints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      width: width * 0.87, // Set a fixed width
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
        padding:
            EdgeInsets.symmetric(vertical: height * 0.02, horizontal: width * 0.1), // Inner padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department, // Fire icon
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
                    SizedBox(width: 8), // Space between icon and text
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
      padding: EdgeInsets.symmetric(
          horizontal: 15, vertical: 12), // Left-Right: 16, Top-Bottom: 12
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
          // Changed from Row to Column
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

  Widget _buildActivitySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyStreak(context),
          const SizedBox(height: 35),
          _buildHistorySection(context),
        ],
      ),
    );
  }

  Widget _buildWeeklyStreak(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.getTranslatedText(context, 'Weekly Streak'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["M", "T", "W", "T", "F", "S", "S"]
                .map((day) => _buildStreakDay(day, day == "M" || day == "T"))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDay(String day, bool isActive) {
    return Column(
      children: [
        Text(day,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 6),
        CircleAvatar(
          backgroundColor:
              isActive ? Colors.black : const Color.fromARGB(136, 0, 0, 0),
          child: isActive
              ? const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 30,
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.getTranslatedText(context, 'History'),
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 2", 3),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Quiz')} - 2", 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 1", 3),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Daily Streak'),
            L10n.getTranslatedText(context, 'Attendance'),
            L10n.getTranslatedText(context, 'Profile'), 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Quiz')} - 2", 1),
        _buildHistoryItem(L10n.getTranslatedText(context, 'Liner Algebra'),
            L10n.getTranslatedText(context, 'Mathematics'),
            "${L10n.getTranslatedText(context, 'Module')} - 1", 3),
      ],
    );
  }

  Widget _buildHistoryItem(
      String title, String subtitle, String detail, int points) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              Text(
                detail,
                style: TextStyle(color: AcademeTheme.appColor, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              Text("+$points",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 30),
            ],
          ),
        ],
      ),
    );
  }
}
