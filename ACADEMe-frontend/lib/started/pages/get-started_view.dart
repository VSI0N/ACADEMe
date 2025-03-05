import 'package:ACADEMe/started/pages/signup_view.dart';
import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class GetStartedView extends StatefulWidget {
  const GetStartedView({super.key});

  @override
  _GetStartedViewState createState() => _GetStartedViewState();
}

class _GetStartedViewState extends State<GetStartedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bigCircleAnimation;
  late Animation<double> _mediumCircleAnimation;
  late Animation<double> _smallCircleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _shrinkAnimation;
  late Animation<double> _nextScreenOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    // Faster beginning animations (10% faster)
    _bigCircleAnimation = Tween<double>(begin: 0, end: 350).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45,
            curve: Curves.easeOut), // Adjusted interval
      ),
    );

    _mediumCircleAnimation = Tween<double>(begin: 0, end: 290).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.5,
            curve: Curves.easeOut), // Adjusted interval
      ),
    );

    _smallCircleAnimation = Tween<double>(begin: 0, end: 260).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.55,
            curve: Curves.easeOut), // Adjusted interval
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            const Interval(0.2, 0.7, curve: Curves.easeIn), // Adjusted interval
      ),
    );

    // More time for shrink animation (smoother)
    _shrinkAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0,
            curve: Curves.easeInOutCubic), // Adjusted interval
      ),
    );

    _nextScreenOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            const Interval(0.55, 1, curve: Curves.easeIn), // Adjusted interval
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final backgroundColor = Color.lerp(
          AcademeTheme.appColor,
          Colors.white,
          _nextScreenOpacity.value,
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: <Widget>[
              // Content (Initially Hidden)
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Image.asset(
                        'assets/academe/study_image.png',
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Image.asset(
                        'assets/academe/academe_logo.png',
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 64, right: 64, top: 10),
                      child: Text(
                        L10n.getTranslatedText(context, 'Level up your learning!'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: AcademeTheme.fontName),
                      ),
                    ),
                    const SizedBox(
                      height: 130,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpView()),
                          );
                        },
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.only(
                            left: 90.0,
                            right: 90.0,
                            top: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromRGBO(254, 223, 0, 1.000),
                          ),
                          child: Text(
                            L10n.getTranslatedText(context, 'Get Started'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 0, 0, 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Circle Animation (Initially Visible)
              Positioned(
                top: 100,
                left: -120,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double shrinkFactor = _shrinkAnimation.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: shrinkFactor,
                            child: Container(
                              width: _bigCircleAnimation.value + 80,
                              height: _bigCircleAnimation.value + 80,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 251, 217, 133),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: shrinkFactor,
                            child: Container(
                              width: _mediumCircleAnimation.value + 40,
                              height: _mediumCircleAnimation.value + 40,
                              decoration: BoxDecoration(
                                color: Colors.yellow[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: shrinkFactor,
                            child: Container(
                              width: _smallCircleAnimation.value,
                              height: _smallCircleAnimation.value,
                              decoration: BoxDecoration(
                                color: Colors.yellow[200],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: _textFadeAnimation,
                            child: Transform.scale(
                              scale: shrinkFactor,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    L10n.getTranslatedText(context, 'Level Up!'),
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Text(
                                    L10n.getTranslatedText(context, 'your'),
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Text(
                                    L10n.getTranslatedText(context, 'learning'),
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
