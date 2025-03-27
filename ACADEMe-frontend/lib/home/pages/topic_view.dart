import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/home/courses/overview/overview.dart';

class TopicViewScreen extends StatefulWidget {
  final String courseId;

  const TopicViewScreen({super.key, required this.courseId});

  @override
  State<TopicViewScreen> createState() => _TopicViewScreenState();
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
    _fetchTopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopics() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'access_token');
    String? courseId = await storage.read(key: 'course_id');

    if (token == null || courseId == null) {
      debugPrint("❌ No access token or course ID found");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      String targetLanguage = languageProvider.locale.languageCode;

      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = jsonDecode(responseBody);

        List<Map<String, dynamic>> allTopics = [];
        List<Map<String, dynamic>> ongoing = [];
        List<Map<String, dynamic>> completed = [];

        for (var topic in data) {
          double progress = topic["progress"] ?? 0.0;

          Map<String, dynamic> topicData = {
            "id": topic["id"],
            "title": utf8.encode(topic["title"]),
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
        debugPrint("❌ Failed to fetch topics: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching topics: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
      return const Center(
          child: CircularProgressIndicator(color: AcademeTheme.appColor));
    }
    if (topicList.isEmpty) {
      return Center(
          child: Text(L10n.getTranslatedText(context, 'No topics available')));
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
      onTap: () => _navigateToOverview(topic),
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(utf8.decode(topic["title"]),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (topic["progress"] / 100).clamp(0.0, 1.0),
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              L10n.getTranslatedText(context, '0/12 Modules'))),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(topic["progress"].clamp(0.0, 1.0) * 100).toInt()}% ",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToOverview(Map<String, dynamic> topic) async {
    await storage.write(key: 'topic_id', value: topic["id"]);
    String? courseId = await storage.read(key: 'course_id');

    if (courseId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OverviewScreen(courseId: courseId, topicId: topic["id"]),
        ),
      );
    } else {
      debugPrint("❌ Course ID not found in storage.");
    }
  }
}
