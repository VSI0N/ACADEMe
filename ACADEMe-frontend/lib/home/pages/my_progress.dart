import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/MotivationPopup.dart';
import 'package:ACADEMe/localization/l10n.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProgressScreen(),
  ));
}

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                                            L10n.getTranslatedText(context, 'Summary'),
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
                                            L10n.getTranslatedText(context, 'Progress'),
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
                                            L10n.getTranslatedText(context, 'Activity'),
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
                                        child: _buildActivitySection(),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                L10n.getTranslatedText(context, 'Average Study Time'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24, // Slightly transparent white
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'This Week'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Text(
            "2h 45m",
            style: TextStyle(
              color: const Color.fromARGB(193, 255, 255, 255),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(height: 170, width: 1000, child: _buildBarChart()),
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
              FlLine(color: Colors.white.withOpacity(0.2), strokeWidth: 1),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildSummaryItem(L10n.getTranslatedText(context, 'Total Courses'), "4"),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildSummaryItem(L10n.getTranslatedText(context, 'Completed'), "2"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child:
              _buildSummaryItem(L10n.getTranslatedText(context, 'Overall Grade'), "87.00", isCircular: true),
            ),
          ),
          const SizedBox(height: 16),

          // **Pass context here**
          _buildMotivationCard(context),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const MotivationPopup(), // Updated call
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.getTranslatedText(context, 'You\'re doing Great!'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  L10n.getTranslatedText(context, 'Learn about your weak points'),
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value,
      {bool isCircular = false}) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 12), // More left & right padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft, // Align text to the left
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
                      value, // Shows the numeric grade (87.00)
                      style: TextStyle(
                        fontSize: 52, // Made it even bigger
                        fontWeight: FontWeight.bold,
                        color: AcademeTheme.appColor, // Changed color to blue
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90, // Bigger progress indicator
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 87 / 100, // Convert to percentage
                            backgroundColor: Colors.grey[300],
                            color: AcademeTheme.appColor,
                            strokeWidth: 8, // Thicker progress bar
                          ),
                        ),
                        Text(
                          "A+", // Shows the letter grade inside
                          style: TextStyle(
                            fontSize: 28, // Bigger letter grade
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 54, // Made non-circular text larger too
                    fontWeight: FontWeight.bold,
                    color: AcademeTheme.appColor, // Changed color to blue
                  ),
                ),
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
          _buildSectionTitle(L10n.getTranslatedText(context, 'Course Progress')),
          _buildCourseCard(L10n.getTranslatedText(context, 'Linear Algebra'), L10n.getTranslatedText(context, 'Mathematics'), 80, L10n.getTranslatedText(context, '10 Modules')),
          _buildCourseCard(L10n.getTranslatedText(context, 'Organic Chemistry'), L10n.getTranslatedText(context, 'Chemistry'), 25, L10n.getTranslatedText(context, '5 Modules')),
          _buildCourseCard(L10n.getTranslatedText(context, 'Linear Algebra'), L10n.getTranslatedText(context, 'Mathematics'), 80, L10n.getTranslatedText(context, '10 Modules')),
          _buildQuizScores(),
        ],
      ),
    );
  }

  Widget _buildMePoints(BuildContext context) {
    return Container(
      width: 380, // Set a fixed width
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
            EdgeInsets.symmetric(vertical: 25, horizontal: 16), // Inner padding
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
              L10n.getTranslatedText(context, 'Redeem your points'),
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
            color: Colors.grey.withOpacity(0.2),
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

  Widget _buildQuizScores() {
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
            _buildQuizScoreHeader(),
            SizedBox(height: 10),
            _buildQuizScoreBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScoreHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your quiz scores",
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
                  "Last 30 days",
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

  Widget _buildQuizScoreBars() {
    return Column(
      children: [
        _buildBar("Maths", 0.9),
        _buildBar("Chem", 0.6),
        _buildBar("Phys", 0.2),
        _buildBar("English", 0.4),
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

  Widget _buildActivitySection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyStreak(),
          const SizedBox(height: 35),
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildWeeklyStreak() {
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
          const Text(
            "Weekly Streak",
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "History",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildHistoryItem("Liner Algebra", "Mathematics", "Module - 2", 3),
        _buildHistoryItem("Liner Algebra", "Mathematics", "Quiz - 2", 1),
        _buildHistoryItem("Liner Algebra", "Mathematics", "Module - 1", 3),
        _buildHistoryItem("Daily Streak", "Attendance", "Profile", 1),
        _buildHistoryItem("Liner Algebra", "Mathematics", "Quiz - 2", 1),
        _buildHistoryItem("Liner Algebra", "Mathematics", "Module - 1", 3),
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
