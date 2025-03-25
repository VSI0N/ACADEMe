import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
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
                  L10n.getTranslatedText(context, 'A day ago'),
                  AImages.QnA_user,
                  23,
                  5,
                ),
                buildQAItem(
                  "Jenny Barry",
                  L10n.getTranslatedText(context, 'A day ago'),
                  "AImages.QnA_user",
                  23,
                  5,
                ),
              ],
            ),
          ),
          buildInputField(context),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget buildQAItem(String name, String time, String imageUrl, int likes, int comments) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!), // Outline border color grey
      ),
        // elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
    child: Container(
    color: Colors.white,
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.grey, size: 18),
                    SizedBox(width: 5),
                    Text(likes.toString()),
                  ],
                ),
                SizedBox(width: 18,),
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
    )
    );
  }

  Widget buildInputField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12), // Adjust padding
                hintText: L10n.getTranslatedText(context, 'Write a comment'),
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
                    color: AcademeTheme.appColor,
                    width: 1,
                  ),
                ),
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
