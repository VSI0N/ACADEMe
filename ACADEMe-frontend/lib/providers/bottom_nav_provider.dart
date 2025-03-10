import 'package:flutter/material.dart';

class BottomNavProvider with ChangeNotifier {
  int _selectedIndex = 0; // Default index (Home tab)

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
