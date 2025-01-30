import '../../academe_theme.dart';
import 'package:flutter/material.dart';

class LogInView extends StatelessWidget {
  final AnimationController animationController;
  const LogInView({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
    Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          0.6,
          0.8,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );
    final secondHalfAnimation =
    Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          0.8,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );

    final welcomeFirstHalfAnimation =
    Tween<Offset>(begin: Offset(2, 0), end: Offset(0, 0))
        .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    final welcomeImageAnimation =
    Tween<Offset>(begin: Offset(4, 0), end: Offset(0, 0))
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
        child: Scaffold( //
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 200, top: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: welcomeImageAnimation,
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: 400, maxHeight: 400),
                        child: Image.asset(
                          'assets/academe/academe_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  Container(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.6,
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                        color: AcademeTheme.white,
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(1, 1),
                              color: Colors.grey,
                              blurRadius: 10)
                        ],
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: welcomeFirstHalfAnimation,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30),
                                  child: Text(
                                    "Welcome",
                                    style: TextStyle(
                                      fontSize: 35.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30),
                                  child: Text(
                                    "Create an Account",
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: Color(0xFF808080),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        Padding(
                          padding: EdgeInsets.only(left: 30,
                              right: 30,
                              top: 16),
                          child: TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AcademeTheme.notWhite,
                              labelText: "Email",
                              hintText: "Enter your email",
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 30,
                              right: 30,
                              top: 16),
                          child: TextFormField(
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AcademeTheme.notWhite,
                              labelText: "Password",
                              hintText: "Enter your password",
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: Icon(Icons.visibility),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 20, right: 40),
                          child: Row(
                            children: [
                              Checkbox(
                                value: false,
                                onChanged: (value) {

                                },
                              ),
                              Text(
                                "I agree to terms and conditions",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
