import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class ChatSession {
  final String title;
  final String timestamp;

  ChatSession({required this.title, required this.timestamp});
}

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final Function(ChatSession) onSelectChat;

  const ChatHistoryDrawer({
    Key? key,
    required this.chatHistory,
    required this.onSelectChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          MediaQuery.of(context).size.width * 0.8, // Set width to 80% of screen
      child: Drawer(
        child: Column(
          children: [
            // Header with Profile Picture, Username, and Search Bar
            Container(
              height: 220, // Adjusted height for the header
              decoration: BoxDecoration(
                color: AcademeTheme.appColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 50, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row for Profile Picture and Username
                    Row(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 30, // Adjusted radius for the avatar
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person,
                              size: 35, color: AcademeTheme.appColor),
                        ),
                        SizedBox(width: 20), // Space between avatar and text
                        // Username
                        Text(
                          "Atomic",
                          style: TextStyle(
                            fontFamily: 'poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 27, // Adjusted font size for the username
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: 20), // Space between username and search bar
                    // Search Bar
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: L10n.getTranslatedText(context, 'Search Chat History...'),
                          border: InputBorder.none,
                          icon:
                              Icon(Icons.search, color: AcademeTheme.appColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigation Links Section
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
              child: ListTile(
                leading:
                    Icon(Icons.chat, color: AcademeTheme.appColor, size: 25),
                title: Text(
                  L10n.getTranslatedText(context, 'Chat History'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                },
              ),
            ),
            Divider(),

            // Chat Sessions List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ListView.builder(
                  itemCount: chatHistory.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: Icon(
                          Icons.history,
                          color: AcademeTheme.appColor,
                          size: 28,
                        ),
                        title: Text(
                          chatHistory[index].title,
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 20),
                        ),
                        subtitle: Text(chatHistory[index].timestamp),
                        onTap: () {
                          onSelectChat(chatHistory[index]);
                          Navigator.pop(
                              context); // Close drawer after selection
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
