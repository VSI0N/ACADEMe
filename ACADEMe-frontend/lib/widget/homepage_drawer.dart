import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:ACADEMe/introduction_page.dart';
import 'package:ACADEMe/home/pages/course_view.dart';
import 'package:ACADEMe/home/pages/profile.dart';
import 'package:ACADEMe/home/pages/ASKMe.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/pages/my_progress.dart';

class HomepageDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const HomepageDrawer({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo aligned slightly to the left
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 0),
            child: SizedBox(
              height: 60,
              width: 300,
              child: Image.asset(
                'assets/academe/academe_logo.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Drawer Items with Navigation
          _buildDrawerItem(Icons.bookmark, "Bookmarks", () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) =>
            //         const BookmarksScreen(), // Directly navigate to BookmarksScreen
            //   ),
            // );
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ProfilePage(), // Directly navigate to ProfileScreen
              ),
            );
          }),
          _buildDrawerItem(Icons.menu_book, "My Courses", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CourseListScreen(), // Directly navigate to CourseListScreen
              ),
            );
          }),
          _buildDrawerItem(Icons.show_chart, "My Progress", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProgressScreen(), // Directly navigate to ProgressScreen
              ),
            );
          }),
          _buildDrawerItem(Icons.headset_mic, "ASKMe", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ASKMe(), // Directly navigate to AskMeScreen
              ),
            );
          }),
          _buildDrawerItem(Icons.settings, "Settings", () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) =>
            //         const SettingsScreen(), // Directly navigate to SettingsScreen
            //   ),
            // );
          }),
          _buildDrawerItem(Icons.help_outline, "Get Help", () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) =>
            //         const HelpScreen(), // Directly navigate to HelpScreen
            //   ),
            // );
          }),

          // Spacer to push user section to the bottom
          const Spacer(),

          // User Profile Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Circular Avatar with Border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        AssetImage('assets/design_course/userImage.png'),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "User Name",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent, size: 28),
                  onPressed: () async {
                    try {
                      await AuthService().signOut();
                      print('✅ User signed out successfully');

                      // Navigate to the introduction screen after logout
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const AcademeScreen()),
                      );
                    } catch (e) {
                      print('❌ Error during logout: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, // Handle onTap action here
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color.fromARGB(255, 214, 238, 242),
          highlightColor: const Color.fromARGB(255, 166, 221, 239),
          child: ListTile(
            leading: Icon(icon, color: Colors.black, size: 28),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
