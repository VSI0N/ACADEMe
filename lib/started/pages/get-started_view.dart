import 'package:ACADEMe/started/pages/signup_view.dart';
import 'package:flutter/material.dart';

import '../../academe_theme.dart';

class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            offset: Offset(0, -50),
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
            offset: Offset(0, -50),
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
            padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpView()),
                );
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
    );
  }
}
