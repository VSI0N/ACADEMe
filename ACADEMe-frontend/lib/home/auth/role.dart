import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRoleManager {
  static final UserRoleManager _instance = UserRoleManager._internal();
  bool isAdmin = false;

  factory UserRoleManager() {
    return _instance;
  }

  UserRoleManager._internal();

  Future<void> fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isAdmin = AdminRoles.isAdmin(user.email ?? "");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', isAdmin);
    }
  }

  Future<void> loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool('isAdmin') ?? false;
  }
}


class AdminRoles {
  static final List<String> adminEmails = [
    "dasp69833@gmail.com",
    "atomic7002@gmail.com",
    "darrang48@gmail.com",
    "ayan.m.dev@gmail.com"
  ];

  static bool isAdmin(String email) {
    return adminEmails.contains(email.trim());
  }
}