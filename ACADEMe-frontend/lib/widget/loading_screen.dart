import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(31, 215, 231, 235).withAlpha(20), // 50% opacity
      body: const Center(
        child: CircularProgressIndicator(
          color: Colors.blue, // Change color to match your theme
        ),
      ),
    );
  }
}
