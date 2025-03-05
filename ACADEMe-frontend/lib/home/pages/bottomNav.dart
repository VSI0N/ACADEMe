import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import '../../started/pages/course.dart';
import '../admin_panel/courses.dart';
import 'course_view.dart';
import 'home_view.dart';
import 'my_community.dart';
import 'my_courses.dart';
import 'package:ACADEMe/home/pages/profile.dart';

class BottomNav extends StatefulWidget {
  final bool isAdmin;
  const BottomNav({super.key, required this.isAdmin});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = widget.isAdmin
        ? [
      HomePage(
        onProfileTap: () {
          setState(() {
            _selectedIndex = 3; // Navigate to Profile tab when user image is tapped
          });
        },
        onAskMeTap: () {
          setState(() {
            _selectedIndex = 1; // Navigate to Chatbot tab when ASKMe card is tapped
          });
        },
      ),
      const CourseListScreen(),
      const Mycommunity(),
      const ProfilePage(),
      CourseManagementScreen()
    ]
        : [HomePage(
      onProfileTap: () {
        setState(() {
          _selectedIndex = 3; // Navigate to Profile tab when user image is tapped
        });
      },
      onAskMeTap: () {
        setState(() {
          _selectedIndex = 1; // Navigate to Chatbot tab when ASKMe card is tapped
        });
      },
    ), CourseListScreen(), Mycommunity(), ProfilePage()];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AcademeTheme.appColor.withOpacity(0.9),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: widget.isAdmin
            ? [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ]
            : [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
