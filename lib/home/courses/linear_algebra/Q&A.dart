import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/utils/constants/image_strings.dart';
import 'package:flutter/material.dart';

class QASection extends StatelessWidget {
  final String userImage = "https://via.placeholder.com/50"; // Replace with actual user image URL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                buildQAItem(
                  "Thomas",
                  "A day ago",
                  AImages.QnA_user,
                  23,
                  5,
                ),
                buildQAItem(
                  "Jenny Barry",
                  "A day ago",
                  "AImages.QnA_user",
                  23,
                  5,
                ),
              ],
            ),
          ),
          buildInputField(),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget buildQAItem(String name, String time, String imageUrl, int likes, int comments) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(imageUrl),
                  radius: 22,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Deserunt minim incididunt cillum nostrud do voluptate excepteur excepteur minim ex minim est.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey, size: 18),
                    SizedBox(width: 5),
                    Text(likes.toString()),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.comment, color: Colors.grey, size: 18),
                    SizedBox(width: 5),
                    Text("$comments Comment"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Write a Q&A...",
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: AcademeTheme.appColor,
            child: Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
