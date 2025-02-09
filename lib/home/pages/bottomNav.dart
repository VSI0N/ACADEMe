import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/home/pages/my_courses.dart';
import 'package:ACADEMe/home/pages/home_view.dart';
import 'package:ACADEMe/home/pages/profile.dart';
import 'package:ACADEMe/home/pages/my_community.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0; // Track the selected tab

  // Define pages for each section
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
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
      const HomeScreen(),
      const Mycommunity(),
      const ProfilePage(),
    ]);
  }

  // Function to handle navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight the selected icon
        onTap: _onItemTapped, // Handle taps
        selectedItemColor: AcademeTheme.appColor, // Active tab color
        unselectedItemColor: Colors.grey, // Inactive tab color
        showUnselectedLabels: true, // Show labels for all tabs
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school, size: 25.0),
            label: 'My Courses',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'My Community',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}