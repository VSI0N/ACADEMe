import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';
import '../../utils/constants/image_strings.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';
import 'package:ACADEMe/home/components/ASKMe_button.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  _CourseListScreenState createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> courses = [
    {
      "title": "UX Foundation",
      "duration": "2 hrs 25 mins",
      "progress": 0.3,
      "image": AImages.product_design,
    },
    {
      "title": "Creative Art Design",
      "duration": "3 hrs 25 mins",
      "progress": 0.7,
      "image": AImages.art_design,
    },
    {
      "title": "Palettes for Your App",
      "duration": "4 hrs 50 mins",
      "progress": 1.0,
      "image": AImages.app_color_schemes,
    },
    {
      "title": "Typography in UI Design",
      "duration": "4 hrs 50 mins",
      "progress": 0.5,
      "image": AImages.typography,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ASKMe()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            "My Courses",
            style: TextStyle(
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
                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 4, color: Colors.blue),
                ),
                tabs: [
                  Tab(text: "ALL"),
                  Tab(text: "ON GOING"),
                  Tab(text: "COMPLETED"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseList(), // All Courses
                  _buildFilteredCourses(ongoing: true), // Ongoing Courses
                  _buildFilteredCourses(ongoing: false), // Completed Courses
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(courses[index]);
      },
    );
  }

  Widget _buildFilteredCourses({required bool ongoing}) {
    List<Map<String, dynamic>> filteredCourses = courses.where((course) {
      return ongoing ? course["progress"] < 1.0 : course["progress"] >= 1.0;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(filteredCourses[index]);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Container(
      height: 150, // Adjusted height of the box
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(10),
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
          Expanded(
            flex: 2, // Adjusting the space distribution
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                course["image"],
                fit: BoxFit.cover, // Ensures the image fills the entire space
                height: double.infinity,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3, // Allocating more space to text content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  course["title"],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  course["duration"],
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * (course["progress"] * 0.6), // Adjusted width calculation
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  "${(course["progress"].clamp(0.0, 1.0) * 100).toInt()}% Complete",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
