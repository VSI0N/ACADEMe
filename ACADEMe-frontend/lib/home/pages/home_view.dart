import 'package:flutter/material.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/components/ASKMe_button.dart';
import 'package:ACADEMe/widget/homepage_drawer.dart';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ACADEMe/home/pages/my_progress.dart';
import '../../localization/l10n.dart';
import 'package:ACADEMe/home/courses/overview/overview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:ACADEMe/home/pages/topic_view.dart'; // Import the TopicViewScreen

class HomePage extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onAskMeTap;
  final int selectedIndex; // Add selectedIndex
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _showSearchUI = ValueNotifier(false); // Use ValueNotifier
  List<dynamic> courses = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  HomePage({
    Key? key,
    required this.onProfileTap,
    required this.onAskMeTap,
    required this.selectedIndex, // Add selectedIndex
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showSearchUI,
      builder: (context, showSearch, child) {
        return Scaffold(
          body: showSearch ? _buildSearchUI(context) : _buildMainUI(context),
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
    final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _secureStorage.read(key: 'access_token');

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
      return data; // Return all courses
    } else {
      throw Exception("❌ Failed to fetch courses: ${response.statusCode}");
    }
  }

  Future<void> _fetchAndStoreUserDetails() async {
    try {
      final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
      final String? token = await _secureStorage.read(key: 'access_token');

      if (token == null) {
        throw Exception("❌ No access token found");
      }

      final response = await http.get(
        Uri.parse("$backendUrl/api/users/me"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Store user details in secure storage
        await _secureStorage.write(key: 'name', value: data['name']);
        await _secureStorage.write(key: 'email', value: data['email']);
        await _secureStorage.write(key: 'student_class', value: data['student_class']);
        await _secureStorage.write(key: 'photo_url', value: data['photo_url']);

        print("✅ User details stored successfully");
      } else {
        throw Exception("❌ Failed to fetch user details: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching user details: $e");
    }
  }

  Widget _buildSearchUI(BuildContext context) {
    // Hide the status bar when the search UI is open
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    ValueNotifier<List<String>> _searchResults = ValueNotifier([]);
    TextEditingController _searchController = TextEditingController();
    List<String> _allCourses = [];

    Future<void> _loadCourses() async {
      try {
        List<dynamic> courses = await _fetchCourses();
        _allCourses = courses.map((course) => course["title"].toString()).toList();
        _searchResults.value = _allCourses;
      } catch (e) {
        print("❌ Error fetching courses: $e");
      }
    }

    void _searchCourses(String query) {
      if (query.isEmpty) {
        _searchResults.value = _allCourses;
        return;
      }
      _searchResults.value = _allCourses
          .where((title) => title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    _loadCourses(); // Load courses on UI open

    return GestureDetector(
      onTap: () {
        _showSearchUI.value = false;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
      },
      behavior: HitTestBehavior.opaque,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _searchCourses,
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
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Popular Searches",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          ActionChip(
                            label: Text("Machine Learning"),
                            onPressed: () {
                              print("Machine Learning clicked");
                            },
                          ),
                          ActionChip(
                            label: Text("Data Science"),
                            onPressed: () {
                              print("Data Science clicked");
                            },
                          ),
                          ActionChip(
                            label: Text("Flutter"),
                            onPressed: () {
                              print("Flutter clicked");
                            },
                          ),
                          ActionChip(
                            label: Text("Linear Algebra"),
                            onPressed: () {
                              print("Linear Algebra clicked");
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Search Results",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ValueListenableBuilder<List<String>>(
                        valueListenable: _searchResults,
                        builder: (context, results, _) {
                          return Column(
                            children: results
                                .map(
                                  (title) => ListTile(
                                leading: Icon(Icons.book),
                                title: Text(title),
                                onTap: () {
                                  print("Selected: $title");
                                },
                              ),
                            )
                                .toList(),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Recent Searches",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.history),
                        title: Text("Advanced Python"),
                        onTap: () {},
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
      ),
    );
  }

  Widget _buildMainUI(BuildContext context) {
    // GlobalKey for controlling the Scaffold state (drawer)
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    TextEditingController _messageController = TextEditingController();

    // Fetch and store user details when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAndStoreUserDetails();
    });

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
              padding: const EdgeInsets.only(top: 15.0), // Adjust top padding here
              child: FutureBuilder<Map<String, String?>>(
                future: _getUserDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading user details"));
                  } else {
                    final String name = snapshot.data?['name'] ?? 'User';
                    final String photoUrl = snapshot.data?['photo_url'] ?? 'assets/design_course/userImage.png';
                    return getAppBarUI(
                      onProfileTap,
                          () {
                        scaffoldKey.currentState?.openDrawer(); // Open drawer when custom button is clicked
                      },
                      context,
                      name,
                      photoUrl,
                      _pageController,
                      selectedIndex,
                    );
                  }
                },
              ),
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
                child: ListView( // Replace SingleChildScrollView with ListView
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0), // Upper padding
                      child: TextField(
                        onTap: () {
                          _showSearchUI.value = true; // Update state properly
                        },
                        decoration: InputDecoration(
                          hintText: L10n.getTranslatedText(context, 'search'),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 8.0), // Spacing
                            child: Transform.rotate(
                              angle: -1.57, // Rotate 90 degrees counterclockwise
                              child: const Icon(Icons.tune), // Rotated Tune Icon (Vertical)
                            ),
                          ),
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(Icons.search), // Search icon on the right
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
                            color: Colors.black.withOpacity(0.1), // Subtle shadow
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
                                  padding: EdgeInsets.all(7), // Adjust padding to reduce image size
                                  child: ClipOval(
                                    child: Image.asset(
                                      "assets/icons/ASKMe.png",
                                      fit: BoxFit.contain, // Ensures the image fits within the padding
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Texts
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    L10n.getTranslatedText(context, 'Your Personal Tutor'),
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 10, 10, 10),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800, // Even bolder than FontWeight.bold
                                      fontFamily: "Roboto", // Use built-in font
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
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Adjust padding
                                      hintText: L10n.getTranslatedText(context, 'ASKMe Anything...'),
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                  icon: const Icon(Icons.send, color: Colors.blue, size: 24),
                                  onPressed: () {
                                    String message = _messageController.text.trim(); // ✅ Get typed message
                                    if (message.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ASKMe(initialMessage: message),
                                        ),
                                      );
                                      _messageController.clear(); // Optional: Clear after sending
                                    }
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
                          MaterialPageRoute(builder: (context) => ProgressScreen()),
                        );
                      },
                      child: Card(
                        color: Colors.indigoAccent, // Background color similar to the image
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0), // Rounded edges
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Section: Title & Subtitle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    L10n.getTranslatedText(context, 'My Progress'),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    L10n.getTranslatedText(context, 'Track your progress'),
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
                                      color: const Color.fromARGB(255, 247, 177, 55), // Fire icon background
                                    ),
                                    child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "420",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'Continue Learning'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Text(
                          L10n.getTranslatedText(context, 'See All'),
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<dynamic>>(
                      future: _fetchCourses(), // Fetching courses
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "❌ Error: ${snapshot.error}",
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text("No courses available"));
                        } else {
                          final courses = snapshot.data!;

                          return Column(
                            children: List.generate(
                              courses.length > 3 ? 3 : courses.length, // Show only 3 courses
                                  (index) => Column(
                                children: [
                                  learningCard(
                                    courses[index]["title"],
                                    4, // Placeholder values
                                    9,
                                    34,
                                    predefinedColors.length > index
                                        ? predefinedColors[index]!
                                        : Colors.primaries[index % Colors.primaries.length][100]!,
                                        () {
                                      // Debug log to confirm the courseId
                                      print("Course ID: ${courses[index]["id"]}");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TopicViewScreen(
                                            courseId: courses[index]["id"], // Pass the courseId
                                          ),
                                        ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  L10n.getTranslatedText(context, 'All Courses'),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Handle 'See All' action
                                  },
                                  child: Text(
                                    L10n.getTranslatedText(context, 'See All'),
                                    style: TextStyle(fontSize: 16, color: Colors.blue),
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
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10), // Reduced height
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(color: Colors.red, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4), // Smaller circle
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red.withOpacity(0.2),
                                              ),
                                              child: Icon(Icons.book, size: 16, color: Colors.red),
                                            ),
                                            SizedBox(width: 10),
                                            Text(L10n.getTranslatedText(context, 'English'),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.orange, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.orange.withOpacity(0.2),
                                              ),
                                              child: Icon(Icons.calculate, size: 16, color: Colors.orange),
                                            ),
                                            SizedBox(width: 10),
                                            Text(L10n.getTranslatedText(context, 'Maths'),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.blue, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.blue.withOpacity(0.2),
                                              ),
                                              child: Icon(Icons.language, size: 16, color: Colors.blue),
                                            ),
                                            SizedBox(width: 10),
                                            Text(L10n.getTranslatedText(context, 'Language'),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.green, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green.withOpacity(0.2),
                                              ),
                                              child: Icon(Icons.science, size: 16, color: Colors.green),
                                            ),
                                            SizedBox(width: 10),
                                            Text(L10n.getTranslatedText(context, 'Biology'),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  L10n.getTranslatedText(context, 'My Courses'),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Handle 'See All' action
                                  },
                                  child: Text(
                                    L10n.getTranslatedText(context, 'See All'),
                                    style: TextStyle(fontSize: 16, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          FutureBuilder<List<dynamic>>(
                            future: _fetchCourses(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    "❌ Error: ${snapshot.error}",
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(child: Text("No courses available"));
                              } else {
                                final courses = snapshot.data!;

                                return Container(
                                  width: double.infinity, // Ensures ListView gets full width
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: courses.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: 170,
                                        margin: EdgeInsets.only(
                                          left: index == 0 ? 16 : 8,
                                          right: index == courses.length - 1 ? 16 : 0,
                                        ),
                                        child: CourseCard(
                                          courses[index]["title"],
                                          "${(index + 10) * 2} Lessons",
                                          repeatingColors[index % repeatingColors.length]!,
                                          onTap: () {
                                            // Debug log to confirm the courseId
                                            print("Course ID: ${courses[index]["id"]}");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TopicViewScreen(
                                                  courseId: courses[index]["id"], // Pass the courseId
                                                ),
                                              ),
                                            );
                                          },
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CourseCard(
                                    "Marketing",
                                    "9 Lessons",
                                    Colors.pink[100]!,
                                    onTap: () {
                                      // Navigate to TopicViewScreen with a placeholder courseId
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => TopicViewScreen(courseId: 1), // Replace with actual courseId
                                      //   ),
                                      // );
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: CourseCard(
                                    "Trading",
                                    "14 Lessons",
                                    Colors.green[100]!,
                                    onTap: () {
                                      // Navigate to TopicViewScreen with a placeholder courseId
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => TopicViewScreen(courseId: 2), // Replace with actual courseId
                                      //   ),
                                      // );
                                    },
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
              ),
            ],
          ),
        ),
        // Use drawer for left-side drawer
        // Use drawer for left-side drawer
        drawer: HomepageDrawer(
          onClose: () {
            Navigator.of(context).pop(); // Close the drawer when tapped
          },
          onProfileTap: onProfileTap, // Pass the onProfileTap callback here
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

Widget learningCard(String title, int completed, int total, int percentage, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
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
    ),
  );
}

// AppBar UI with the Hamburger icon inside a circular button
Widget getAppBarUI(
    VoidCallback onProfileTap,
    VoidCallback onHamburgerTap,
    BuildContext context,
    String name,
    String photoUrl,
    PageController pageController,
    int selectedIndex,
    ) {
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
            backgroundImage: photoUrl.startsWith('http')
                ? NetworkImage(photoUrl) as ImageProvider
                : AssetImage(photoUrl),
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
              name, // Dynamically set this if needed
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
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true, // Tapping outside closes it
                barrierLabel: "Dismiss",
                barrierColor: Colors.black.withOpacity(0.3), // Dim background
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 1,
                      child: Material(
                        color: Colors.white,
                        child: HomepageDrawer(
                          onClose: () {
                            Navigator.of(context).pop(); // Close drawer manually
                          },
                          onProfileTap: onProfileTap, // Pass the onProfileTap callback here
                        ),
                      ),
                    ),
                  );
                },
                transitionBuilder: (context, animation, secondaryAnimation, child) {
                  // Slide in from left
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              );
            },
            // Open the drawer when clicked
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
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          padding: EdgeInsets.all(8), // Smaller circle
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
  final VoidCallback onTap; // Add this line

  const CourseCard(
      this.title,
      this.subtitle,
      this.color, {
        Key? key,
        required this.onTap, // Add this line
      }) : super(key: key);

  /// **Function to Get Subject-Specific Icons**
  IconData _getSubjectIcon(String title) {
    switch (title.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
        return Icons.calculate; // Math Icon
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science; // Science Icon
      case 'english':
      case 'language':
        return Icons.menu_book; // English Icon
      case 'computer':
      case 'programming':
      case 'coding':
        return Icons.computer; // Computer Icon
      case 'history':
      case 'geography':
      case 'social studies':
        return Icons.public; // History Icon
      default:
        return Icons.school; // Default Icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Use the onTap callback here
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getSubjectIcon(title), // Dynamically fetch icon
              size: 50, // Increased size to fit inside the box
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
      ),
    );
  }
}

// Function to fetch user details from secure storage
Future<Map<String, String?>> _getUserDetails() async {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final String? name = await _secureStorage.read(key: 'name');
  final String? photoUrl = await _secureStorage.read(key: 'photo_url');
  return {
    'name': name,
    'photo_url': photoUrl,
  };
}