import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TestReportScreen extends StatefulWidget {
  const TestReportScreen({super.key});

  @override
  TestReportScreenState createState() => TestReportScreenState();
}

class TestReportScreenState extends State<TestReportScreen> {
  Map<String, dynamic> visualData = {};
  bool isLoading = true;
  double overallAverage = 0;
  // SharedPreferences? _storage;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _initStorage() async {
    fetchProgressData();
  }

  Future<void> fetchProgressData() async {
    setState(() => isLoading = true);

    try {
      final String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token - Please login again');
      }

      // Use the correct URL that works with your curl request
      final response = await http.get(
        Uri.parse('$backendUrl/api/progress-visuals/'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json', // Added accept header
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);

        setState(() {
          visualData = jsonData;
          overallAverage = calculateOverallAverage(jsonData['visual_data']);
        });
      } else {
        throw Exception('Failed to load progress data: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) {
        return; // ✅ Ensure widget is still mounted before using context
      }
      debugPrint('❌ Error fetching progress data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  double calculateOverallAverage(Map<String, dynamic> visualData) {
    double totalScore = 0;
    int totalQuizzes = 0;

    visualData.forEach((key, userData) {
      if (userData['quizzes'] > 0) {
        totalScore += (userData['avg_score'] as num).toDouble() *
            (userData['quizzes'] as num).toInt();
        totalQuizzes += (userData['quizzes'] as num).toInt();
      }
    });

    return totalQuizzes > 0 ? totalScore / totalQuizzes : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.getTranslatedText(context, 'Test Report'),
            style: GoogleFonts.poppins(fontSize: 22, color: Colors.white)),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

  // 1. Score Summary Card - Updated with dynamic values
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
            Text(L10n.getTranslatedText(context, 'Overall Score'),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${overallAverage.toStringAsFixed(0)}/100",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                CircularProgressIndicator(
                  value: overallAverage / 100,
                  color: _getProgressColor(overallAverage),
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

  // 2. Performance Graph - Kept exactly the same
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
            bottomTitles: AxisTitles(
                sideTitles: _bottomTitles(
                    ["Plant", "Animal", "Matter", "Mul", "Div"])),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Bar Chart Helper - Kept exactly the same
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
        return Text(topics[value.toInt()],
            style: TextStyle(color: Colors.black, fontSize: 12));
      },
    );
  }

  // 3. Detailed Analysis - Kept exactly the same
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
            Text(L10n.getTranslatedText(context, 'Detailed Performance'),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            SizedBox(height: 10),
            _buildPerformanceRow(L10n.getTranslatedText(context, 'Correct Answers'), "40/50", Colors.green),
            _buildPerformanceRow(
                L10n.getTranslatedText(context, 'Incorrect Answers'), "10/50", Colors.redAccent),
            _buildPerformanceRow(L10n.getTranslatedText(context, 'Skipped Questions'), "5", Colors.orangeAccent),
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
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // 4. Action Buttons (Download & Share) - Kept exactly the same
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
            Icons.picture_as_pdf, L10n.getTranslatedText(context, 'Download Report'), Colors.white),
        _buildActionButton(Icons.share, L10n.getTranslatedText(context, 'Share Score'), Colors.white),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.black),
      label: Text(label,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getProgressColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
