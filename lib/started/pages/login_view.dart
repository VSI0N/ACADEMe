import 'package:ACADEMe/started/pages/signup_view.dart';

import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 200, top: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: 400, maxHeight: 400),
                    child: Image.asset(
                      'assets/academe/academe_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 50),
                Container(
                  height: MediaQuery.of(context).size.height * 0.63,
                  margin: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
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
                      Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 30, right: 30),
                              child: Text(
                                "Hello",
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
                                "Welcome back",
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
                      SizedBox(height: 50),
                      Padding(
                        padding: EdgeInsets.only(left: 30, right: 30, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left side)
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0), // Adds space between text and text field
                              child: Text(
                                "Email", // Add the text you want
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54, // Adjust color as needed
                                  fontWeight: FontWeight.w700, // Adjust weight as needed
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AcademeTheme.notWhite,
                                labelText: "Email",
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
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0), // Adds space between text and text field
                              child: Text(
                                "Password", // Add the text you want
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54, // Adjust color as needed
                                  fontWeight: FontWeight.w700, // Adjust weight as needed
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AcademeTheme.notWhite,
                                labelText: "Password",
                                hintText: "Enter your password",
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off),
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
                          ],
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
                              style: TextStyle(
                                color: AcademeTheme.appColor, // Change this to your desired color
                                fontWeight: FontWeight.w500, // Optional: Make it bold
                                fontSize: 14, // Optional: Adjust font size
                              ),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35),
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
                                    fontSize: 18, // Font size
                                    fontWeight: FontWeight.w400, // Font weight
                                    color: Colors.black, // Text color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6,),
                      Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
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

                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 16,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AcademeTheme.appColor, // Change color for emphasis
                              ),
                            ),
                          ),
                        ],
                      ),// Adds spacing before the "Log In" button
                    ],
                  ),
                ),
                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}