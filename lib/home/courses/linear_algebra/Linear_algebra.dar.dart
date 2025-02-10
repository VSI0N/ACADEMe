import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'Q&A.dart';
import 'lessons.dart';
import 'overview.dart';
import 'package:ACADEMe/academe_theme.dart';

class LinearAlgebraScreen extends StatefulWidget {
  const LinearAlgebraScreen({super.key});

  @override
  _LinearAlgebraScreenState createState() => _LinearAlgebraScreenState();
}

class _LinearAlgebraScreenState extends State<LinearAlgebraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late VideoPlayerController _videoController;
  bool _isVideoPlaying = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    // Initialize Video Player
    _videoController = VideoPlayerController.network(
        'https://www.youtube.com/watch?v=kjBOesZCoqc' // Replace with your video URL
    )..initialize().then((_) {
      setState(() {}); // Refresh UI when video is initialized
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Course details",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          Padding(
            padding: EdgeInsets.only(top: 230), // Offset for fixed video section
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mathematics Linear Algebra Section
                          Text(
                            "Mathematics: Linear Algebra",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(" 4.5 (1233) ",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("• 9 lessons",
                                  style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Divider(color: Colors.black, thickness: 0.2),
                          SizedBox(height: 5),
                          // Your Progress Section
                          Text("Your Progress",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: 20 / 100,
                              color: AcademeTheme.appColor,
                              backgroundColor: Colors.grey[300],
                              minHeight: 10,
                            ),
                          ),
                          SizedBox(height: 15),
                          Divider(color: Colors.black, thickness: 0.2),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AcademeTheme.appColor,
                        unselectedLabelColor: Colors.black,
                        indicatorColor: AcademeTheme.appColor,
                        labelStyle: TextStyle(fontSize: 18),
                        tabs: [
                          Tab(text: "OVERVIEW"),
                          Tab(text: "LESSONS"),
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
                  OverviewSection(),
                  LessonsSection(),
                  QASection(),
                ],
              ),
            ),
          ),

          // Fixed Video Section
          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(color: Colors.purple[100]),
            child: Stack(
              children: [
                // Video Player
                Center(
                  child: _videoController.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                      : CircularProgressIndicator(),
                ),

                // Play Button Overlay
                if (!_isVideoPlaying)
                  Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(color: Colors.purple[100]),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 70,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mathematics",
                                  style: TextStyle(fontSize: 20, color: Colors.black)),
                              Text("Linear \nAlgebra",
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: Colors.deepPurple[700],
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  )),
                            ],
                          ),
                        ),
                        // Center(
                        //   child: GestureDetector(
                        //     onTap: () {},
                        //     child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                        //   ),
                        // ),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isVideoPlaying = true;
                                _videoController.play();
                              });
                            },
                            child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

              ],
            ),
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
