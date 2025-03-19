import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../academe_theme.dart';
import '../admin_panel/courses.dart';
import 'course_view.dart';
import 'home_view.dart';
import 'my_community.dart';
import 'package:ACADEMe/home/pages/profile.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/providers/bottom_nav_provider.dart'; // Import provider

class BottomNav extends StatelessWidget {
  final bool isAdmin;
  const BottomNav({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        final int selectedIndex = bottomNavProvider.selectedIndex;

        final List<Widget> pages = isAdmin
            ? [
          HomePage(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onAskMeTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex, // Pass selectedIndex here
          ),
          const CourseListScreen(),
          const Mycommunity(),
          const ProfilePage(),
          CourseManagementScreen(),
        ]
            : [
          HomePage(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onAskMeTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex, // Pass selectedIndex here
          ),
          CourseListScreen(),
          Mycommunity(),
          ProfilePage(),
        ];

        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: bottomNavProvider.setIndex,
            selectedItemColor: AcademeTheme.appColor.withOpacity(0.9),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: isAdmin
                ? [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: L10n.getTranslatedText(context, 'Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: L10n.getTranslatedText(context, 'Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: L10n.getTranslatedText(context, 'Admin')),
            ]
                : [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: L10n.getTranslatedText(context, 'Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: L10n.getTranslatedText(context, 'Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
            ],
          ),
        );
      },
    );
  }
}