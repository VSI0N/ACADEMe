import 'package:ACADEMe/started/pages/signup_view.dart';

import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';

import '../../home/pages/forgot_password.dart';

class LogInView extends StatefulWidget {
  const LogInView({super.key});

  @override
  State<LogInView> createState() => _LogInViewState();
}

class _LogInViewState extends State<LogInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final (user, errorMessage) = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage ?? 'Login failed. Invalid credentials')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the terms and conditions')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    final (user, errorMessage) = await AuthService().signInWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in with Google successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'Google Sign-In failed. Please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
          children: [
      Positioned.fill(
      child:LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            constraints: BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.0),
                  Image.asset(
                    'assets/academe/academe_logo.png',
                    height: constraints.maxHeight * 0.23,
                  ),
                  // SizedBox(height: screenHeight * 0.001),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: AcademeTheme.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(1, 1),
                          color: Colors.grey,
                          blurRadius: 10,
                        )
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello", style: TextStyle(fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold)),
                          Text("Welcome back", style: TextStyle(fontSize: screenWidth * 0.047, color: Colors.grey, fontWeight: FontWeight.bold)),
                          SizedBox(height: screenHeight * 0.02),
                          Text("Email", style: TextStyle(fontSize: screenWidth * 0.043, color: Colors.black54, fontWeight: FontWeight.w700)),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AcademeTheme.notWhite,
                              hintText: "Enter your email",
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text("Password", style: TextStyle(fontSize: screenWidth * 0.043, color: Colors.black54, fontWeight: FontWeight.w700)),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AcademeTheme.notWhite,
                              hintText: "Enter your password",
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AcademeTheme.appColor, // Change this to your desired color
                                    fontWeight: FontWeight.w500, // Optional: Make it bold
                                    fontSize: 14, // Optional: Adjust font size
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow[600], // Button background color
                                  minimumSize: Size(double.infinity, 42), // Set the height of the button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30), // Rounded corners
                                  ),
                                  elevation: 0, // Removes shadow
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Centers the content
                                  children: [
                                    Image.asset(
                                      'assets/icons/house_door.png', // Replace with your image path
                                      height: 24, // Adjust the size of the image
                                      width: 24, // Adjust the size of the image
                                    ),
                                    SizedBox(width: 10), // Adds space between the image and the text
                                    Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045, // Font size
                                        fontWeight: FontWeight.w500, // Font weight
                                        color: Colors.black, // Text color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("OR", style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600, color: Colors.black54)),
                            ],),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                                icon: _isGoogleLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Padding(
                                  padding: EdgeInsets.only(right: 7), // Adjust spacing
                                  child: Image.asset('assets/icons/google_icon.png', height: 22),
                                ),
                                label: Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  color: Colors.black54,
                                ),
                              ),
                              TextButton(
                                onPressed: (
                                    ) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignUpView()),
                                  );
                                },
                                child: Text(
                                  "Signup",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.w500,
                                    color: AcademeTheme.appColor, // Change color for emphasis
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    )
    ]
      )
    );
  }
}