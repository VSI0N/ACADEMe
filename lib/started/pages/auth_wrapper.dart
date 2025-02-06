import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ACADEMe/introduction_page.dart';
import 'package:ACADEMe/home/pages/home_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ✅ Persist login state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading state
        } else if (snapshot.hasData) {
          return const HomeScreen(); // ✅ User is logged in
        } else {
          return const AcademeScreen(); // ✅ User is NOT logged in
        }
      },
    );
  }
}
