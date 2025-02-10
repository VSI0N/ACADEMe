import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String imagePath;
  final String courseName;
  final String teacher;
  final double rating;
  final int reviews;
  final int lessons;

  const CourseCard({
    Key? key,
    required this.imagePath,
    required this.courseName,
    required this.teacher,
    required this.rating,
    required this.reviews,
    required this.lessons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130, // Matches the image height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.asset(
              imagePath, // Use dynamic image path
              width: 130, // Adjust width to fit better
              height: 150, // Make height equal to container height
              fit: BoxFit.cover, // Ensures image fills space properly
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 1),
                  Text(
                    courseName, // Dynamic course name
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    teacher, // Dynamic teacher name
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        " $rating ($reviews) ", // Dynamic rating and reviews
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "• $lessons lessons", // Dynamic lessons count
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, left: 4), // Adjusted padding
              child: IconButton(
                icon: const Icon(
                  Icons.bookmark_border,
                  size: 34,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
