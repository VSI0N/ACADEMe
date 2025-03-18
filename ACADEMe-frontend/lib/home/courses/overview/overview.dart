import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Q&A.dart';
import 'lessons.dart';
import 'package:ACADEMe/academe_theme.dart';

class OverviewScreen extends StatefulWidget {
  final String courseId;
  final String topicId;

  const OverviewScreen({super.key, required this.courseId, required this.topicId});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

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

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🔹 API Response: ${response.body}"); // ✅ Log the response

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            final Map<String, dynamic> data = jsonData[0];
            updateTopicDetails(data);
          } else {
            print("❌ Unexpected JSON format (List but empty or incorrect structure)");
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
      topicDescription = data["description"]?.toString() ?? "No description available.";
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              /// **🔹 Responsive Gradient Header**
              Container(
                width: double.infinity,
                height: screenHeight * 0.3, // 30% of the screen height
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF967EF6), Color(0xFFE8DAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05, // 5% of screen width
                    vertical: screenHeight * 0.05, // 5% of screen height
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            "Topic details",
                            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.bookmark_border, color: Colors.black),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02), // 2% of screen height
                      Text(
                        isLoading ? "Loading..." : topicTitle,
                        style: TextStyle(
                          fontSize: screenWidth * 0.08, // 8% of screen width
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01), // 1% of screen height
                      Text(
                        isLoading ? "Fetching topic details..." : topicDescription,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, // 4% of screen width
                          color: Colors.black,
                        ),
                      ),
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
                          padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your Progress",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: screenHeight * 0.005), // Small spacing
                              const Text("0/12 Modules"),
                              SizedBox(height: screenHeight * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: 0.0,
                                  color: AcademeTheme.appColor,
                                  backgroundColor: const Color(0xFFE8E5FB),
                                  minHeight: screenHeight * 0.012, // Responsive height
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              const Divider(color: Colors.grey, thickness: 0.5),
                              SizedBox(height: screenHeight * 0.005),
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
                            labelStyle: TextStyle(fontSize: screenWidth * 0.045), // Responsive font size
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
                      LessonsSection(courseId: widget.courseId, topicId: widget.topicId),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
