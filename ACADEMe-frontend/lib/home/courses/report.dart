import 'package:ACADEMe/home/admin_panel/courses.dart';
import 'package:ACADEMe/home/pages/course_view.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/components/ASKMe_button.dart';
import 'package:ACADEMe/widget/homepage_drawer.dart';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ACADEMe/home/pages/my_progress.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/providers/bottom_nav_provider.dart';
import '../../localization/l10n.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/home/courses/overview/overview.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onAskMeTap;
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _showSearchUI =
      ValueNotifier(false); // Use ValueNotifier
  List<dynamic> courses = [];

  HomePage({
    Key? key,
    required this.onProfileTap,
    required this.onAskMeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showSearchUI,
      builder: (context, showSearch, child) {
        return Scaffold(
          body: showSearch ? _buildSearchUI() : _buildMainUI(context),
        );
      },
    );
  }

  final List<Color?> predefinedColors = [
    Colors.pink[100],
    Colors.blue[100],
    Colors.green[100]
  ];

  final List<Color?> repeatingColors = [Colors.green[100], Colors.pink[100]];

  Future<List<dynamic>> _fetchCourses() async {
    final String backendUrl =
        dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token =
        await const FlutterSecureStorage().read(key: 'access_token');

    if (token == null) {
      throw Exception("❌ No access token found");
    }

    final response = await http.get(
      Uri.parse("$backendUrl/api/courses/?target_language=en"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.take(3).toList(); // Return only the first 3 courses
    } else {
      throw Exception("❌ Failed to fetch courses: ${response.statusCode}");
    }
  }

  Widget _buildSearchUI() {
    return GestureDetector(
      onTap: () {
        _showSearchUI.value = false; // Update notifier instead of setState()
      },
      behavior: HitTestBehavior.opaque, // Ensures taps outside are detected
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              // Ensures content scrolls
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Popular Searches",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ActionChip(
                          label: Text("Machine Learning"),
                          onPressed: () {
                            print("Machine Learning clicked");
                            // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Data Science"),
                          onPressed: () {
                            print("Data Science clicked");
                            // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Flutter"),
                          onPressed: () {
                            print("Flutter clicked");
                            // Handle chip click action here
                          },
                        ),
                        ActionChip(
                          label: Text("Linear Algebra"),
                          onPressed: () {
                            print("Linear Algebra clicked");
                            // Handle chip click action here
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Recent Searches",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text("Advanced Python"),
                      onTap: () {}, // Keep these as they are
                    ),
                    ListTile(
                      leading: Icon(Icons.history),
                      title: Text("Cyber Security"),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI(BuildContext context) {
    // GlobalKey for controlling the Scaffold state (drawer)
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    return ASKMeButton(
      showFAB: true, // Show floating action button
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ASKMe()),
        );
      },

      child: Scaffold(
        key: scaffoldKey, // Assign the scaffold key
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(105), // Increased height
          child: AppBar(
            backgroundColor: AcademeTheme.appColor,
            automaticallyImplyLeading: false,
            elevation: 0,
            leading: Container(), // Remove default hamburger
            flexibleSpace: Padding(
              padding:
                  const EdgeInsets.only(top: 15.0), // Adjust top padding here
              child: getAppBarUI(onProfileTap, () {
                scaffoldKey.currentState
                    ?.openDrawer(); // Open drawer when custom button is clicked
              }, context),
            ),
          ),
        ),
        // Use drawer for left-side drawer
        backgroundColor: AcademeTheme.appColor, // Set background same as AppBar

        body: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), // Rounded upper edges
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            // Use Column instead of SingleChildScrollView
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 10.0), // Upper padding
                        child: TextField(
                          onTap: () {
                            _showSearchUI.value = true; // Update state properly
                          },
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12.0, right: 8.0), // Spacing
                              child: Transform.rotate(
                                angle:
                                    -1.57, // Rotate 90 degrees counterclockwise
                                child: const Icon(
                                    Icons.tune), // Rotated Tune Icon (Vertical)
                              ),
                            ),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 12.0),
                              child: Icon(
                                  Icons.search), // Search icon on the right
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(205, 232, 238, 239),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: Colors.grey.shade300, // Border color
                            width: 1.5, // Border width
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.1), // Subtle shadow
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Circular Image Container
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        7), // Adjust padding to reduce image size
                                    child: ClipOval(
                                      child: Image.asset(
                                        "assets/icons/ASKMe.png",
                                        fit: BoxFit
                                            .contain, // Ensures the image fits within the padding
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Texts
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Your Personal Tutor",
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 10, 10, 10),
                                        fontSize: 24,
                                        fontWeight: FontWeight
                                            .w800, // Even bolder than FontWeight.bold
                                        fontFamily:
                                            "Roboto", // Use built-in font
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "ASKMe",
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 9, 9, 9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Input Field with Send Icon
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40, // Adjust this value as needed
                                    child: TextField(
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 12), // Adjust padding
                                        hintText: "ASKMe Anything...",
                                        hintStyle:
                                            TextStyle(color: Colors.grey[600]),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Send Icon Outside
                                Transform.rotate(
                                  angle: -pi / 4, // Rotates 45° to the left
                                  child: IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.blue, size: 24),
                                    onPressed: () {
                                      // Send button action
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // My Progress Section
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProgressScreen()),
                          );
                        },
                        child: Card(
                          color: Colors
                              .indigoAccent, // Background color similar to the image
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12.0), // Rounded edges
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left Section: Title & Subtitle
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      L10n.getTranslatedText(
                                          context, 'My Progress'),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      L10n.getTranslatedText(
                                          context, 'Track your progress'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                // Right Section: Fire Icon with Badge
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color.fromARGB(255, 247,
                                            177, 55), // Fire icon background
                                      ),
                                      child: const Icon(
                                          Icons.local_fire_department,
                                          color: Colors.white,
                                          size: 24),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "420",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Continue Learning",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text(
                            "See All",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<dynamic>>(
                        future: _fetchCourses(), // Fetching courses
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "❌ Error: ${snapshot.error}",
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text("No courses available"));
                          } else {
                            final courses = snapshot.data!;

                            return Column(
                              children: List.generate(
                                courses.length,
                                (index) => Column(
                                  children: [
                                    learningCard(
                                      courses[index]["title"],
                                      4, // ✅ Placeholder values (adjust if API provides progress)
                                      9,
                                      34,
                                      predefinedColors.length > index
                                          ? predefinedColors[
                                              index]! // ✅ Use predefined colors for first 3 courses
                                          : Colors.primaries[index %
                                                  Colors.primaries.length]
                                              [100]!, // ✅ Fallback color
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  OverviewScreen(
                                                      courseId: 'courseId',
                                                      topicId: 'topicId')),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // **Swipeable Banner**
                            buildSwipeableBanner(_pageController),

                            SizedBox(height: 16),

                            // **All Courses Section with "See All" Button**
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "All Courses",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Handle 'See All' action
                                    },
                                    child: Text(
                                      "See All",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8),

                            // **Course Boxes - Two Per Row**
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 10), // Reduced height
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            border: Border.all(
                                                color: Colors.red, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                    4), // Smaller circle
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red
                                                      .withOpacity(0.2),
                                                ),
                                                child: Icon(Icons.book,
                                                    size: 16,
                                                    color: Colors.red),
                                              ),
                                              SizedBox(width: 10),
                                              Text("English",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.orange,
                                                width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.orange
                                                      .withOpacity(0.2),
                                                ),
                                                child: Icon(Icons.calculate,
                                                    size: 16,
                                                    color: Colors.orange),
                                              ),
                                              SizedBox(width: 10),
                                              Text("Maths",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.blue, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue
                                                      .withOpacity(0.2),
                                                ),
                                                child: Icon(Icons.language,
                                                    size: 16,
                                                    color: Colors.blue),
                                              ),
                                              SizedBox(width: 10),
                                              Text("Language",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green,
                                                width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green
                                                      .withOpacity(0.2),
                                                ),
                                                child: Icon(Icons.science,
                                                    size: 16,
                                                    color: Colors.green),
                                              ),
                                              SizedBox(width: 10),
                                              Text("Biology",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // **My Courses Section**
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "My Courses",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Handle 'See All' action
                                    },
                                    child: Text(
                                      "See All",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            FutureBuilder<List<dynamic>>(
                              future: _fetchCourses(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      "❌ Error: ${snapshot.error}",
                                      style: TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text("No courses available"));
                                } else {
                                  final courses = snapshot.data!;

                                  return SizedBox(
                                    height: 160, // ✅ Fixed height
                                    child: ListView.builder(
                                      scrollDirection: Axis
                                          .horizontal, // ✅ Enables horizontal scrolling
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: courses.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width:
                                              180, // ✅ Fixed width for each course card
                                          margin: const EdgeInsets.only(
                                              left: 16), // ✅ Adds spacing
                                          child: CourseCard(
                                            courses[index][
                                                "title"], // ✅ Course Title from API
                                            "${(index + 10) * 2} Lessons", // ✅ Placeholder lesson count
                                            repeatingColors[index %
                                                repeatingColors
                                                    .length]!, // ✅ Alternating colors
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),

                            SizedBox(height: 16),

                            // **Recommended Section**
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Recommended",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CourseCard("Marketing", "9 Lessons",
                                        Colors.pink[100]!),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: CourseCard("Trading", "14 Lessons",
                                        Colors.green[100]!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Use drawer for left-side drawer
        drawer: HomepageDrawer(
          onClose: () {
            Navigator.of(context).pop(); // Close the drawer when tapped
          },
          onProfileTap: () {
            // Handle navigation to the fourth option (Profile) of the bottom navigation bar
            // Example: If you're using a PageController or BottomNavigationBar, update the index here
            // _selectedIndex = 3; // Assuming 3 is the index for the Profile page
            // _pageController.jumpToPage(3); // If using a PageController
          },
        ),
        // Modify drawerEdgeDragWidth to make it open from the right
        drawerEdgeDragWidth: double.infinity, // Make drawer full-width and allow dragging from anywhere
        endDrawerEnableOpenDragGesture: true, // Allow drag to open the drawer from the right
      ),
    );
  }
}

Widget barGraph(double yellowHeight, double purpleHeight) {
  return Column(
    children: [
      Container(
        height: purpleHeight,
        width: 22,
        decoration: BoxDecoration(
          color: Colors.grey,
        ),
      ),
      Container(
        height: yellowHeight,
        width: 24,
        decoration: BoxDecoration(
          color: Colors.yellow,
        ),
      ),
    ],
  );
}

Widget learningCard(String title, int completed, int total, int percentage,
    Color color, VoidCallback onTap) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text("$completed / $total"),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: percentage / 100,
                color: Colors.blue,
                backgroundColor: Colors.grey[300],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
              onPressed: onTap,
            ),
            const SizedBox(height: 10),
            Text("$percentage%"),
          ],
        ),
      ],
    ),
  );
}

// AppBar UI with the Hamburger icon inside a circular button
Widget getAppBarUI(VoidCallback onProfileTap, VoidCallback onHamburgerTap,
    BuildContext context) {
  return Container(
    height: 100, // Increased height for the AppBar
    padding: const EdgeInsets.only(top: 38.0, left: 18, right: 18, bottom: 5),
    child: Row(
      children: <Widget>[
        // Profile Picture
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 30, // Slightly larger for a prominent look
            backgroundImage: AssetImage('assets/design_course/userImage.png'),
          ),
        ),
        const SizedBox(width: 12), // Space between profile picture and text

        // Greeting and Username (arranged vertically)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Hello'),
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              'Alex', // Dynamically set this if needed
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const Spacer(), // Pushes the menu icon to the right

        // Hamburger Menu Icon inside a circular button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // White background
          ),
          width: 40, // Fixed width for the circular container
          height: 40, // Fixed height to ensure the circle is smaller
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.black, // Black menu icon
              size: 20, // Icon size
            ),
            onPressed: onHamburgerTap, // Open the drawer when clicked
          ),
        ),
      ],
    ),
  );
}

// Widget for section headers
class SectionHeader extends StatelessWidget {
  final String title;

  SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("See All", style: TextStyle(color: Colors.blue, fontSize: 14)),
      ],
    );
  }
}

// **Function for Swipeable Banner**
Widget buildSwipeableBanner(PageController controller) {
  return Container(
    height: 140, // Adjusted height for ads + indicator
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: controller,
            children: [
              adContainer(Colors.purple[200]!, ""),
              adContainer(Colors.blue[200]!, ""),
              adContainer(Colors.green[200]!, ""),
            ],
          ),
        ),
        SizedBox(height: 8),
        SmoothPageIndicator(
          controller: controller,
          count: 3,
          effect: ExpandingDotsEffect(
            activeDotColor: Colors.purple,
            dotColor: Colors.grey[300]!,
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 2,
          ),
        ),
      ],
    ),
  );
}

// **Function to Create an Ad Container**
Widget adContainer(Color color, String text) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// Widget for course tags
class CourseTag extends StatelessWidget {
  final String text;
  final Color color;

  CourseTag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }
}

Widget CourseBox(IconData icon, String label, Color color) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

// Widget for course cards
class CourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const CourseCard(this.title, this.subtitle, this.color, {Key? key})
      : super(key: key);

  /// **Function to Get Subject-Specific Icons**
  IconData _getSubjectIcon(String title) {
    switch (title.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
        return Icons.calculate; // ✅ Math Icon
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science; // ✅ Science Icon
      case 'english':
      case 'language':
        return Icons.menu_book; // ✅ English Icon
      case 'computer':
      case 'programming':
      case 'coding':
        return Icons.computer; // ✅ Computer Icon
      case 'history':
      case 'geography':
      case 'social studies':
        return Icons.public; // ✅ History Icon
      default:
        return Icons.school; // ✅ Default Icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getSubjectIcon(title), // ✅ Dynamically fetch icon
            size: 50, // ✅ Increased size to fit inside the box
            color: Colors.black.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
