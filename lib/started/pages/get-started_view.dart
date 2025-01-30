import '../../academe_theme.dart';
import 'package:flutter/material.dart';

class GetStartedView extends StatefulWidget {
  final AnimationController animationController;

  const GetStartedView({super.key, required this.animationController});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<GetStartedView> {
  @override
  Widget build(BuildContext context) {
    final introductionanimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(0.0, -1.0))
            .animate(CurvedAnimation(
      parent: widget.animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    return SlideTransition(
      position: introductionanimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 80),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/academe/study_image.png',
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -50), // Adjust the Y offset as needed
              child: Padding(
                padding: EdgeInsets.only(top: 0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.asset(
                    'assets/academe/academe_logo.png',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -50), // Adjust the Y offset as needed
              child: Padding(
                padding: EdgeInsets.only(left: 64, right: 64, top: 10),
                child: Text(
                  "Level up your learning!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: AcademeTheme.fontName),
                ),
              ),
            ),
            SizedBox(
              height: 130,
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16),
              child: InkWell(
                onTap: () {
                  widget.animationController.animateTo(0.2);
                },
                child: Container(
                  height: 58,
                  padding: EdgeInsets.only(
                    left: 90.0,
                    right: 90.0,
                    top: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromRGBO(254, 223, 0, 1.000),
                  ),
                  child: Text(
                    "Get Started",
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
    );
  }
}
