import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';


class TestReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test Report", style: GoogleFonts.poppins(fontSize: 22, color: Colors.white)),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(),
            SizedBox(height: 16),
            _buildPerformanceGraph(),
            SizedBox(height: 16),
            _buildDetailedAnalysis(),
            SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // 1. Score Summary Card
  Widget _buildScoreCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AcademeTheme.appColor,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overall Score", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("85/100", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                CircularProgressIndicator(
                  value: 85 / 100,
                  color: Colors.greenAccent,
                  backgroundColor: Colors.white30,
                  strokeWidth: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Performance Graph
  Widget _buildPerformanceGraph() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: [
            _buildBar(0, 80),
            _buildBar(1, 90),
            _buildBar(2, 60),
            _buildBar(3, 70),
            _buildBar(4, 85),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: _bottomTitles(["Loops", "OOP", "Arrays", "DBMS", "Flutter"])),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Bar Chart Helper
  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.blueAccent, width: 16)],
    );
  }

  SideTitles _bottomTitles(List<String> topics) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        return Text(topics[value.toInt()], style: TextStyle(color: Colors.black, fontSize: 12));
      },
    );
  }

  // 3. Detailed Analysis
  Widget _buildDetailedAnalysis() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detailed Performance", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 10),
            _buildPerformanceRow("Correct Answers", "40/50", Colors.green),
            _buildPerformanceRow("Incorrect Answers", "10/50", Colors.redAccent),
            _buildPerformanceRow("Skipped Questions", "5", Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 4. Action Buttons (Download & Share)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.picture_as_pdf, "Download Report", Colors.white),
        _buildActionButton(Icons.share, "Share Score", Colors.white),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}