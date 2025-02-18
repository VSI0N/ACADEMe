import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/bottomNav.dart';
import 'package:ACADEMe/home/pages/home_view.dart';
import 'package:ACADEMe/introduction_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SelectCourseScreen(),
  ));
}

class SelectCourseScreen extends StatefulWidget {
  @override
  _SelectCourseScreenState createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  List<String> allCourses = [
    "Computer Science", "Mathematics", "Physics", "AI & ML", "Data Science", "Cyber Security",
    "Business Analytics", "Software Engineering", "Blockchain", "Internet of Things", "Game Development",
    "Digital Marketing", "Cloud Computing", "Embedded Systems", "Bioinformatics", "Robotics", "Astronomy",
    "Machine Learning", "Quantum Computing", "Neuroscience", "Philosophy", "Economics", "Psychology",
    "Statistics", "Medical Science"
  ];

  List<String> filteredCourses = [];
  List<String> selectedCourses = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCourses = allCourses; // Initially show all courses
  }

  void filterCourses(String query) {
    setState(() {
      filteredCourses = allCourses
          .where((course) => course.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Course", style: TextStyle(fontWeight: FontWeight.w600,
        color: Colors.white)),
        centerTitle: true,
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Choose your courses:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),

            // Course List (Scrollable)
            Container(
              height: 250, // Fixed height for scrolling
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Search bar inside the course list section
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => filterCourses(value), // Live update results
                      decoration: InputDecoration(
                        hintText: "Search course...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),

                  // Scrollable course list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredCourses[index]),
                          onTap: () {
                            if (!selectedCourses.contains(filteredCourses[index])) {
                              setState(() {
                                selectedCourses.add(filteredCourses[index]);
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            // Selected Courses (Scrollable if needed)
            Wrap(
              spacing: 8,
              children: selectedCourses.map((course) {
                return Chip(
                  label: Text(course, style: TextStyle(color: Colors.white)),
                  backgroundColor: AcademeTheme.appColor,
                  deleteIcon: Icon(Icons.close, color: Colors.white),
                  onDeleted: () {
                    setState(() {
                      selectedCourses.remove(course);
                    });
                  },
                );
              }).toList(),
            ),

            Spacer(),

            // Continue Button
            ElevatedButton(
              onPressed: () {
                if (selectedCourses.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select at least one course")),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BottomNav(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AcademeTheme.appColor,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Center(
                child: Text("Continue", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
