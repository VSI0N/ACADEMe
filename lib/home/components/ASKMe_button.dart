import 'package:ACADEMe/academe_theme.dart';
import 'package:flutter/material.dart';

class ASKMeButton extends StatelessWidget {
  final Widget child;
  final bool showFAB;
  final VoidCallback? onFABPressed; // Callback for FAB press

  const ASKMeButton({
    required this.child,
    this.showFAB = true,
    this.onFABPressed, // Accepting the callback
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child, // Main screen content

          // Floating Action Button (FAB) positioned at the bottom-right
          if (showFAB)
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                backgroundColor: AcademeTheme.appColor,
                onPressed: onFABPressed ?? () {}, // Call the callback if provided
                child: Image.asset(
                  'assets/icons/ASKMe.png', // Replace with your image path
                  width: 40, // Adjust width as needed
                  height: 40, // Adjust height as needed
                  fit: BoxFit.cover, // Ensure the image fits well
                ),
              ),
            ),
        ],
      ),
    );
  }
}
