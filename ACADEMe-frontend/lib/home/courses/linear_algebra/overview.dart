import 'package:ACADEMe/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/image_strings.dart';
import '../../../utils/theme/custom_themes/course_theme.dart';

class OverviewSection extends StatefulWidget {
  @override
  _OverviewSectionState createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  bool showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(), // Keeps full screen scrollable
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructor Info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/images/userImage.png'),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Willam Doddie",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      "PhD in Mathematics",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Description Section
            Text(
              "Description",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Conwallis in semper laoreet nibh leo. Vivamus malesuada ipsum "
                  "pulvinar non rutrum risus dui, risus. Purus massa velit iaculis "
                  "tincidunt tortor, risus, scelerisque risus.",
              maxLines: showFullDescription ? null : 2,
              overflow: showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showFullDescription = !showFullDescription;
                });
              },
              child: Text(
                showFullDescription ? "See less" : "See more",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),

            // Your Courses Section
            Text(
              ATexts.your_course,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Ensuring courses do not overflow
            // ListView.builder(
            //   shrinkWrap: true,
            //   physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
            //   itemCount: 1, // Adjust as needed
            //   itemBuilder: (context, index) {
            //     return CourseCard(
            //       imagePath: 'assets/design_course/product_design.png',
            //       courseName: 'UI/UX Masterclass',
            //       teacher: 'John Doe',
            //       rating: 4.8,
            //       reviews: 980,
            //       lessons: 15,
            //     );
            //     SizedBox(height: 12,);
            //   },
            // ),
            CourseCard(
              imagePath: AImages.product_design,
              courseName: ATexts.UI_UX_course,
              teacher: 'Dennis Sweeney',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
            SizedBox(height: 12),
            CourseCard(
              imagePath: AImages.app_color_schemes,
              courseName: ATexts.pallets_app_course,
              teacher: 'Ramono Wultschner',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
            SizedBox(height: 12),
            CourseCard(
              imagePath: AImages.UI_design,
              courseName: 'Mobile App Design',
              teacher: 'Ramono Wultschner',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
            SizedBox(height: 18),
            Text(
              ATexts.same_courses,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CourseCard(
              imagePath: 'assets/design_course/app_color_schemes.png',
              courseName: 'Palletes for your App',
              teacher: 'Ramono Wultschner',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
            SizedBox(height: 10),
            CourseCard(
              imagePath: 'assets/design_course/app_color_schemes.png',
              courseName: 'Palletes for your App',
              teacher: 'Ramono Wultschner',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
            SizedBox(height: 10),
            CourseCard(
              imagePath: 'assets/design_course/app_color_schemes.png',
              courseName: 'Palletes for your App',
              teacher: 'Ramono Wultschner',
              rating: 4.8,
              reviews: 980,
              lessons: 15,
            ),
          ],
        ),
      ),
    );
  }
}
