import 'dart:convert';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'qna.dart';
import 'lessons.dart';

class OverviewScreen extends StatefulWidget {
  final String courseId;
  final String topicId;

  const OverviewScreen(
      {super.key, required this.courseId, required this.topicId});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  String topicTitle = "Loading...";
  String topicDescription = "Fetching topic details...";
  bool isLoading = true;
  bool hasSubtopicData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchTopicDetails(); // Fetch from topics endpoint
    await fetchSubtopicData(); // Fetch from subtopics endpoint
  }

  Future<void> fetchTopicDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      return;
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("🔹 Topic API Response: ${response.body}");

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        if (jsonData is List) {
          final topic = jsonData.firstWhere(
                (topic) => topic['id'] == widget.topicId,
            orElse: () => null,
          );
          if (topic != null) {
            updateTopicDetails(topic);
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching topic details: $e");
    }
  }

  Future<void> fetchSubtopicData() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      return;
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          hasSubtopicData = true;
        });
      }
    } catch (e) {
      print("❌ Error fetching subtopic data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    setState(() {
      topicTitle = data["title"]?.toString() ?? "Untitled Topic";
      topicDescription =
          data["description"]?.toString() ?? "No description available.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF967EF6), Color(0xFFE8DAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              L10n.getTranslatedText(context, 'Topic details'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.bookmark_border,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                          EdgeInsets.symmetric(horizontal: width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: height * 0.02),
                              Text(
                                isLoading ? "Loading..." : topicTitle,
                                style: TextStyle(
                                  fontSize: width * 0.08,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                isLoading
                                    ? "Fetching topic details..."
                                    : topicDescription,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: Colors.black,
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
              Expanded(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(width * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.getTranslatedText(
                                    context, 'Your Progress'),
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: height * 0.005),
                              Text(
                                  "0/12 ${L10n.getTranslatedText(context, 'Modules')}"),
                              SizedBox(height: height * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: 0.0,
                                  color: AcademeTheme.appColor,
                                  backgroundColor: const Color(0xFFE8E5FB),
                                  minHeight: height * 0.012,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              const Divider(color: Colors.grey, thickness: 0.5),
                              SizedBox(height: height * 0.005),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AcademeTheme.appColor,
                            unselectedLabelColor: Colors.black,
                            indicatorColor: AcademeTheme.appColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(fontSize: width * 0.045),
                            tabs: [
                              Tab(
                                  text: L10n.getTranslatedText(
                                      context, 'Overview')),
                              Tab(text: L10n.getTranslatedText(context, 'Q&A')),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      hasSubtopicData
                          ? LessonsSection(
                          courseId: widget.courseId,
                          topicId: widget.topicId)
                          : Center(child: CircularProgressIndicator()),
                      QSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _StickyTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}