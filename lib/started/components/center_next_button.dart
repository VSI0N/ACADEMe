import '../pages/login_view.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class CenterNextButton extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onNextClick;
  const CenterNextButton(
      {super.key,
        required this.animationController,
        required this.onNextClick});

  @override
  Widget build(BuildContext context) {
    final topMoveAnimation =
    Tween<Offset>(begin: Offset(0, 5), end: Offset(0, 0))
        .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final signUpMoveAnimation =
    Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final loginTextMoveAnimation =
    Tween<Offset>(begin: Offset(0, 3), end: Offset(0, 0))
        .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return Padding(
      padding:
      EdgeInsets.only(bottom: 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SlideTransition(
            position: topMoveAnimation,
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) => AnimatedOpacity(
                opacity: animationController.value >= 0.2 &&
                    animationController.value <= 0.6
                    ? 1
                    : 0,
                duration: Duration(milliseconds: 80),
                child: _pageView(),
              ),
            ),
          ),
          SlideTransition(
            position: topMoveAnimation,
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                double shrinkFactor = 1 - signUpMoveAnimation.value; // Shrink effect

                return Padding(
                  padding: EdgeInsets.only(bottom: 38 * shrinkFactor), // Adjust bottom padding
                  child: Container(
                    height: 58 * shrinkFactor, // Shrink height smoothly
                    width: 58 * shrinkFactor,  // Shrink width smoothly
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 + 32 * shrinkFactor), // Maintain roundness
                      color: Color.fromRGBO(254, 223, 0, shrinkFactor), // Gradual fade-out
                    ),
                    child: Opacity(
                      opacity: shrinkFactor, // Fade out as it shrinks
                      child: PageTransitionSwitcher(
                        duration: Duration(milliseconds: 80),
                        reverse: signUpMoveAnimation.value < 0.7,
                        transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation,
                            ) {
                          return SharedAxisTransition(
                            fillColor: Colors.transparent,
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.vertical,
                            child: child,
                          );
                        },
                        child: shrinkFactor > 0.2 // Hide content completely when almost gone
                            ? InkWell(
                          key: ValueKey('next button'),
                          onTap: onNextClick,
                          child: Padding(
                            padding: EdgeInsets.all(16.0 * shrinkFactor), // Shrinking padding
                            child: Icon(Icons.arrow_forward_ios_rounded,
                                color: Color.fromRGBO(0, 0, 0, shrinkFactor)),
                          ),
                        )
                            : SizedBox(), // Empty widget when fully shrunk
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AnimatedOpacity(
              opacity: animationController.value >= 0.7 ? 0 : 1, // ✅ Instantly hide
              duration: Duration(milliseconds: 0), // ✅ No delay
              child: SlideTransition(
                position: loginTextMoveAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '',
                      style: TextStyle(
                        color: Colors.transparent,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LogInView(
                                    animationController: animationController)));
                      },
                      child: Text(
                        '',
                        style: TextStyle(
                          color: Colors.transparent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageView() {
    int selectedIndex = 0;

    if (animationController.value >= 0.7) {
      selectedIndex = 3;
    } else if (animationController.value >= 0.5) {
      selectedIndex = 2;
    } else if (animationController.value >= 0.3) {
      selectedIndex = 1;
    } else if (animationController.value >= 0.1) {
      selectedIndex = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 480),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: selectedIndex == i
                      ? Color(0xff132137)
                      : Color(0xffE3E4E4),
                ),
                width: 10,
                height: 10,
              ),
            )
        ],
      ),
    );
  }
}
