import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
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
  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();

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

    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) throw Exception("No access token found");
      if (!mounted) return;

      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = languageProvider.locale.languageCode;

      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;

        final allTopics = data.map((topic) {
          return {
            "id": topic["id"].toString(),
            "title": topic["title"].toString(),
            "progress": (topic["progress"] ?? 0.0).toDouble(),
          };
        }).toList();

        setState(() {
          topics = allTopics;
          ongoingTopics = topics
              .where((t) => t["progress"] > 0 && t["progress"] < 100)
              .toList();
          completedTopics = topics.where((t) => t["progress"] == 100).toList();
        });
      } else {
        throw Exception("Failed to fetch topics: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching topics: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading topics: ${e.toString()}")),
        );
      }
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: Colors.blue),
              ),
              tabs: [
                _buildSynchronizedTab(context, 'ALL'),
                _buildSynchronizedTab(context, 'ON GOING'),
                _buildSynchronizedTab(context, 'COMPLETED'),
              ],
            ),
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

  Widget _buildSynchronizedTab(BuildContext context, String labelKey) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: _tabTextGroup, // Ensures all tabs scale together
        style: TextStyle(fontSize: 16),
        minFontSize: 12, // Prevents text from becoming unreadable
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTopicList(List<Map<String, dynamic>> topicList) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }
    if (topicList.isEmpty) {
      return Center(
        child: Text(L10n.getTranslatedText(context, 'No topics available')),
      );
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OverviewScreen(
              courseId: widget.courseId,
              topicId: topic["id"],
            ),
          ),
        );
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
              color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            )
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
                  Text(topic["title"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
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
                          "0/12 ${L10n.getTranslatedText(context, 'Modules')}"),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(topic["progress"].clamp(0.0, 100.0).toInt())}%",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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
}
