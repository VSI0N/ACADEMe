import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProgressController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> fetchCourses() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _storage.read(key: 'access_token');

    if (token == null) throw Exception("❌ No access token found");

    final response = await http.get(
      Uri.parse("$backendUrl/api/courses/?target_language=en"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ Failed to fetch courses: ${response.statusCode}");
    }
  }

  Future<double> fetchOverallGrade() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _storage.read(key: 'access_token');

    if (token == null) throw Exception("❌ No access token found");

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
        // ✅ Calculate overall average score using max_quiz_score from all topics
        double totalMaxScore = 0.0;
        int topicCount = 0;

        visualData.forEach((key, value) {
          // Get max_quiz_score for each topic, default to 0.0 if not found
          double maxQuizScore = (value['max_quiz_score'] ?? 0).toDouble();
          totalMaxScore += maxQuizScore;
          topicCount++;
        });

        // ✅ Calculate overall average: (sum of max_quiz_scores) / number of topics
        double overallAvgScore = topicCount > 0 ? totalMaxScore / topicCount : 0.0;

        return overallAvgScore;
      }
      return 0.0;
    } else {
      throw Exception("❌ Failed to fetch overall grade: ${response.statusCode}");
    }
  }
}