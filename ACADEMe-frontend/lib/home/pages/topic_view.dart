import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../../utils/constants/image_strings.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/home/pages/subtopic_view.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/home/courses/overview/overview.dart';

class TopicViewScreen extends StatefulWidget {
  final String courseId;

  const TopicViewScreen({super.key, required this.courseId});

  @override
  _TopicViewScreenState createState() => _TopicViewScreenState();
}

class _TopicViewScreenState extends State<TopicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> topics = [];
  List<Map<String, dynamic>> ongoingTopics = [];
  List<Map<String, dynamic>> completedTopics = [];
  bool isLoading = true;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTopics() async {
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'access_token');
    String? courseId = await storage.read(key: 'course_id');

    if (token == null || courseId == null) {
      print("❌ No access token or course ID found");
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String targetLanguage =
          Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;

      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/$courseId/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        List<Map<String, dynamic>> allTopics = [];
        List<Map<String, dynamic>> ongoing = [];
        List<Map<String, dynamic>> completed = [];

        for (var topic in data) {
          double progress = topic["progress"] ?? 0.0; // Ensure progress is valid

          Map<String, dynamic> topicData = {
            "id": topic["id"],
            "title": topic["title"],
            "progress": progress,
          };

          allTopics.add(topicData);

          if (progress > 0 && progress < 100) {
            ongoing.add(topicData);
          } else if (progress == 100) {
            completed.add(topicData);
          }
        }

        setState(() {
          topics = allTopics;
          ongoingTopics = ongoing;
          completedTopics = completed;
        });
      } else {
        print("❌ Failed to fetch topics: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching topics: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          L10n.getTranslatedText(context, 'Topics'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontSize: 16),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: Colors.blue),
            ),
            tabs: [
              Tab(text: L10n.getTranslatedText(context, 'ALL')),
              Tab(text: L10n.getTranslatedText(context, 'ON GOING')),
              Tab(text: L10n.getTranslatedText(context, 'COMPLETED')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopicList(topics),
                _buildTopicList(ongoingTopics),
                _buildTopicList(completedTopics),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList(List<Map<String, dynamic>> topicList) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }
    if (topicList.isEmpty) {
      return const Center(child: Text("No topics available"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: topicList.length,
      itemBuilder: (context, index) {
        return _buildTopicCard(topicList[index]);
      },
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () async {
        await storage.write(key: 'topic_id', value: topic["id"]);
        String? courseId = await storage.read(key: 'course_id');

        if (courseId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OverviewScreen(courseId: courseId, topicId: topic["id"]),
            ),
          );
        } else {
          print("❌ Course ID not found in storage.");
        }
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  topic["image"] ?? AImages.typography,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(topic["title"],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (topic["progress"] / 100).clamp(0.0, 1.0), // Ensure it's between 0 and 1
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
