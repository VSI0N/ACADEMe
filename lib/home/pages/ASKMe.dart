import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';

class ASKMe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Invisible Spacer (Keeps "ASKMe" centered)
            Opacity(
              opacity: 0,
              child: IconButton(
                icon: Icon(Icons.menu), // Any dummy icon
                onPressed: () {},
              ),
            ),

            // Centered Title
            Expanded(
              child: Text(
                'ASKMe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),

            // Icons on the Right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: newChatIcon(),
                  onPressed: () {
                    // Handle search functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, size: 28, color: Colors.white),
                  onPressed: () {
                    // Handle new chat functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Greeting
              Column(
                children: [
                  Image.asset(
                    'assets/icons/ASKMe_dark.png',
                    width: 120.0,
                    height: 120.0,
                  ),
                  SizedBox(height: 15),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hey there! I am ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'ASKMe', // This part is deep yellow
                          style: TextStyle(
                            color: Colors.amber[700], // Deep yellow color
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' your\npersonal tutor.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: 40),

              // Buttons Section
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildButton(Icons.help_outline, 'Clear Your Doubts', Colors.lightBlue.shade400),
                  _buildButton(Icons.quiz, 'Explain / Quiz', Colors.orange.shade400),
                  _buildButton(Icons.upload_file, 'Upload Study Materials', Colors.green.shade500),
                  _buildButton(Icons.more_horiz, 'More', Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            // Plus Button for Attachments (Smaller)
            Container(
              width: 40, // Adjusted width
              height: 40, // Adjusted height
              child: IconButton(
                icon: Icon(Icons.add_circle, color: AcademeTheme.appColor, size: 28), // Slightly smaller icon
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext context) {
                      return Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAttachmentOption(context, Icons.image, "Image", Colors.blue),
                            _buildAttachmentOption(context, Icons.insert_drive_file, "Document", Colors.green),
                            _buildAttachmentOption(context, Icons.video_library, "Video", Colors.orange),
                            _buildAttachmentOption(context, Icons.audiotrack, "Audio", Colors.purple),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Text Input Field
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Send Button (Arrow Upward with Circular Background & Ideal Size)
            Container(
              width: 30, // Adjusted width
              height: 30, // Adjusted height
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AcademeTheme.appColor, // Background color
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_upward, color: Colors.white, size: 24), // Adjusted icon size
                onPressed: () {
                  // Handle message send
                },
                padding: EdgeInsets.zero, // Remove extra padding
                constraints: BoxConstraints(), // Prevent expansion
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton(IconData icon, String text, Color color) {
    return ElevatedButton.icon(
      onPressed: () {
        // Button action
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(text),
    );
  }
}

Widget newChatIcon() {
  return Stack(
    clipBehavior: Clip.none, // Allows elements to extend beyond their container
    children: [
      // Chat bubble with slight background effect
      Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AcademeTheme.appColor, // Subtle background effect
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chat_bubble_outline,
          size: 26,
          color: Colors.white,
        ),
      ),

      // Positioned Floating Plus Sign
      Positioned(
        right: -2,
        top: -2,
        child: Container(
          width: 19, // Slightly larger plus circle
          height: 19,
          decoration: BoxDecoration(
            color: AcademeTheme.appColor, // Background color
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2), // White border for better visibility
          ),
          child: Center(
            child: Icon(
              Icons.add,
              size: 12,
              color: Colors.white, // White plus sign for contrast
              weight: 900, // Bold plus sign
            ),
          ),
        ),
      ),
    ],
  );
}

// Function to build attachment options (Pass `context` as a parameter)
Widget _buildAttachmentOption(BuildContext context, IconData icon, String label, Color color) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    onTap: () {
      // Handle file selection logic here
      Navigator.pop(context); // Close modal after selection
    },
  );
}

void main() {
  runApp(MaterialApp(home: ASKMe(), debugShowCheckedModeBanner: false));
}
