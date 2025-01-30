import 'package:flutter/material.dart';

class ProgressView extends StatelessWidget {
  final AnimationController animationController;

  const ProgressView({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.4,
        0.6,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    final moodFirstHalfAnimation =
        Tween<Offset>(begin: Offset(2, 0), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.4,
        0.6,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final moodSecondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-2, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final imageFirstHalfAnimation =
        Tween<Offset>(begin: Offset(4, 0), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.4,
        0.6,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final imageSecondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-4, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return SlideTransition(
      position: firstHalfAnimation,
      child: SlideTransition(
        position: secondHalfAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Progress Tracking",
                style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
              ),
              SlideTransition(
                position: moodFirstHalfAnimation,
                child: SlideTransition(
                  position: moodSecondHalfAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 64, right: 64, top: 16, bottom: 16),
                    child: Text(
                      "AI-driven progress tracking adapts to individual learning needs, bridging knowledge gaps for personalized improvement.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: imageFirstHalfAnimation,
                child: SlideTransition(
                  position: imageSecondHalfAnimation,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 350, maxHeight: 250),
                    child: Image.asset(
                      'assets/academe/progress_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
