import 'package:ACADEMe/home/auth/role.dart';
import 'package:ACADEMe/home/pages/bottomNav.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ACADEMe/introduction_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();


  // @override
  // void initState() {
  //   super.initState();
  //   UserRoleManager().fetchUserRole(); // Fetch user role here after app startup
  // }


  Future<bool> _isUserLoggedIn() async {
    String? token = await _secureStorage.read(key: "access_token");
    return token != null; // ✅ Only check for access token
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data == true) {
          return BottomNav(isAdmin:UserRoleManager().isAdmin,); // ✅ Go to main page if logged in
        } else {
          return const AcademeScreen(); // Show login screen if not logged in
        }
      },
    );
  }
}
