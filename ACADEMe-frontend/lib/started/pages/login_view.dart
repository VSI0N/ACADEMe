import 'package:ACADEMe/started/pages/signup_view.dart';

import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  /// Handles manual login
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter valid credentials')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final (user, errorMessage) = await AuthService().signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      // ❌ Show error if login fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    if (user != null) {
      // ✅ Store user info for later use (optional)
      await _secureStorage.write(key: "user_id", value: user.id);
      await _secureStorage.write(key: "user_name", value: user.name);
      await _secureStorage.write(key: "user_email", value: user.email);
      await _secureStorage.write(key: "student_class", value: user.studentClass);
      await _secureStorage.write(key: "photo_url", value: user.photo_url);

      // ✅ Success! Navigate to home page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Login successful!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // ❌ Fallback error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Login failed. Please try again.')),
      );
    }
  }

  /// Handles Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    final (user, errorMessage) = await AuthService().signInWithGoogle();
    setState(() => _isGoogleLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? '❌ Google Login failed. Please try again')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Logged in successfully with Google!')),
    );
    Navigator.pushReplacementNamed(context, '/home');
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
                                    fontWeight: FontWeight.w500, // Font weight
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