import 'package:flutter/material.dart';
import 'Q&A.dart';
import 'lessons.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF967EF6), // Light Purple (Top)
                      Color(0xFFE8DAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.black),
                          Text("Course details", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                          Icon(Icons.bookmark_border, color: Colors.black),
                        ],
                      ),
                      SizedBox(height: 20),

                      Text("Linear Algebra",
                          style: TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold)),
                      SizedBox(height: 7),
                      Text("Mathematics", style: TextStyle(fontSize: 15, color: AcademeTheme.appColor)),
                      SizedBox(height: 8),
                      Text("Convallis in semper laoreet nibh leo. Vivamus malesuada ipsum pulvinar non rutrum risus dui.",
                          style: TextStyle(fontSize: 14, color: Colors.black)),
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
                          color: Colors.white, // Set background color to white
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Your Progress",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Text("0/12 Modules"),
                                SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: 0.0,
                                    color: AcademeTheme.appColor,
                                    backgroundColor: Color(0xFFE8E5FB),
                                    minHeight: 10,
                                  ),
                                ),
                                SizedBox(height: 15), // Reduce space before the divider
                                Container(
                                  color: Colors.grey, // Ensure background color blends
                                  width: double.infinity, // Ensures it takes the full screen width
                                  child: Divider(
                                    color: Colors.grey,
                                    thickness: 0.5,
                                    height: 0, // Removes extra spacing
                                  ),
                                ),
                                SizedBox(height: 3), // Reduce space after the divider
                              ],
                            ),
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
                            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                            tabs: [
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
                      LessonsSection(),
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