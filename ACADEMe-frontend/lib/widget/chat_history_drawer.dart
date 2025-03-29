import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatSession {
  final String title;
  final String timestamp;

  ChatSession({required this.title, required this.timestamp});
}

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final Function(ChatSession) onSelectChat;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  const ChatHistoryDrawer({
    super.key,
    required this.chatHistory,
    required this.onSelectChat,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Drawer(
        child: Column(
          children: [
            // Header with Profile Picture, Username, and Search Bar
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AcademeTheme.appColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                child: FutureBuilder<Map<String, String?>>(
                  future: _getUserDetails(),
                  builder: (context, snapshot) {
                    final String name = snapshot.data?['name'] ?? 'User';
                    final String? photoUrl = snapshot.data?['photo_url'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for Profile Picture and Username
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: photoUrl != null && photoUrl.isNotEmpty
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/design_course/userImage.png',
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/design_course/userImage.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Username
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 27,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: L10n.getTranslatedText(
                                  context, 'Search Chat History...'),
                              border: InputBorder.none,
                              icon: Icon(Icons.search,
                                  color: AcademeTheme.appColor),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Rest of your existing code...
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
                onTap: () => Navigator.pop(context),
              ),
            ),
            const Divider(),

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
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 20),
                        ),
                        subtitle: Text(chatHistory[index].timestamp),
                        onTap: () {
                          onSelectChat(chatHistory[index]);
                          Navigator.pop(context);
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

  Future<Map<String, String?>> _getUserDetails() async {
    final String? name = await _secureStorage.read(key: 'name');
    final String? photoUrl = await _secureStorage.read(key: 'photo_url');
    return {
      'name': name,
      'photo_url': photoUrl,
    };
  }
}
