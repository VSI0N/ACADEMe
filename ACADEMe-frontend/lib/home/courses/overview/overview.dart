import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'Q&A.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    fetchTopicDetails();
  }

  Future<void> fetchTopicDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ Missing access token");
      return;
    }

    // Get the target language from the app's language provider
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

      print("🔹 API Response: ${response.body}"); // ✅ Log the response

      if (response.statusCode == 200) {
        // Decode the response body using UTF-8
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            final Map<String, dynamic> data = jsonData[0];
            updateTopicDetails(data);
          } else {
            print(
                "❌ Unexpected JSON format (List but empty or incorrect structure)");
          }
        } else if (jsonData is Map<String, dynamic>) {
          updateTopicDetails(jsonData);
        } else {
          print("❌ Unexpected JSON structure: ${jsonData.runtimeType}");
        }
      } else {
        print("❌ Failed to fetch topic details: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching topic details: $e");
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
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              /// **🔹 Responsive Gradient Header**
              Container(
                width: double.infinity,
                height: height * 0.38, // 30% of the screen height
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF967EF6), Color(0xFFE8DAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05, // 5% of screen width
                    vertical: height * 0.05, // 5% of screen height
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
                            flex: 6, // Adjust this to move text slightly left
                            child: const Text(
                              "Topic details",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex:
                                1, // This keeps the bookmark icon slightly to the right
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.03),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        height: height *
                                            0.02), // 2% of screen height
                                    Text(
                                      isLoading ? "Loading..." : topicTitle,
                                      style: TextStyle(
                                        fontSize:
                                            width * 0.08, // 8% of screen width
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                        height: height *
                                            0.01), // 1% of screen height
                                    Text(
                                      isLoading
                                          ? "Fetching topic details..."
                                          : topicDescription,
                                      style: TextStyle(
                                        fontSize:
                                            width * 0.04, // 4% of screen width
                                        color: Colors.black,
                                      ),
                                    ),
                                  ]
                              )
                          )
                      )
                    ],
                  ),
                ),
              ),

              /// **🔹 Course Progress Section**
              Expanded(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(
                              width * 0.04), // 4% of screen width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your Progress",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: height * 0.005), // Small spacing
                              const Text("0/12 Modules"),
                              SizedBox(height: height * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: 0.0,
                                  color: AcademeTheme.appColor,
                                  backgroundColor: const Color(0xFFE8E5FB),
                                  minHeight:
                                      height * 0.012, // Responsive height
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
                            labelStyle: TextStyle(
                                fontSize:
                                    width * 0.045), // Responsive font size
                            tabs: const [
                              Tab(text: "Overview"),
                              Tab(text: "Q&A"),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      LessonsSection(
                          courseId: widget.courseId, topicId: widget.topicId),
                      QASection(),
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

/// **🔹 Sticky Tab Bar Delegate**
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
