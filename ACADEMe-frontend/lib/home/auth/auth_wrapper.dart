import 'package:ACADEMe/home/auth/role.dart';
import 'package:ACADEMe/home/pages/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/introduction_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool? isUserLoggedIn;
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// 🔹 Asynchronously checks login status & loads admin role
  Future<void> _initializeAuth() async {
    String? token = await _secureStorage.read(key: "access_token");

    if (token != null) {
      String? userEmail = await _secureStorage.read(key: "user_email");
      if (userEmail != null) {
        await UserRoleManager().fetchUserRole(userEmail);
      }
      await UserRoleManager().loadRole();
      isAdmin = UserRoleManager().isAdmin;
      setState(() {
        isUserLoggedIn = true;
      });
    } else {
      setState(() {
        isUserLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isUserLoggedIn == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return isUserLoggedIn!
        ? BottomNav(isAdmin: isAdmin ?? false) // ✅ Pass isAdmin correctly
        : const AcademeScreen(); // ❌ Not logged in, show intro/login screen
  }
}
