import 'package:ACADEMe/started/pages/signup_view.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../home/auth/role.dart';
import '../../home/pages/bottomNav.dart';
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
        SnackBar(
            content: Text(L10n.getTranslatedText(
                context, '⚠️ Please enter valid credentials'))),
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
      await _secureStorage.write(
          key: "student_class", value: user.studentClass);
      await _secureStorage.write(key: "photo_url", value: user.photo_url);

      // ✅ Success! Navigate to home page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(L10n.getTranslatedText(context, '✅ Login successful!'))),
      );
// ✅ Success! Navigate to home page
      await UserRoleManager()
          .fetchUserRole(user.email); // ✅ Fetch user role before navigating
      bool isAdmin = UserRoleManager().isAdmin;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNav(isAdmin: isAdmin),
        ),
      );
    } else {
      // ❌ Fallback error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(L10n.getTranslatedText(
                context, '❌ Login failed. Please try again.'))),
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
        SnackBar(
            content: Text(errorMessage ??
                L10n.getTranslatedText(
                    context, '❌ Google Login failed. Please try again'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(L10n.getTranslatedText(
              context, '✅ Logged in successfully with Google!'))),
    );
    Navigator.pushReplacementNamed(context, '/home');
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
                                    Text(L10n.getTranslatedText(context, 'Hello'),
                                        style: TextStyle(fontSize: screenWidth * 0.08, fontWeight: FontWeight.bold)),
                                    Text(L10n.getTranslatedText(context, 'Welcome back'),
                                        style: TextStyle(fontSize: screenWidth * 0.047, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(L10n.getTranslatedText(context, 'Email'),
                                        style: TextStyle(fontSize: screenWidth * 0.043, color: Colors.black54, fontWeight: FontWeight.w700)),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AcademeTheme.notWhite,
                                        hintText: L10n.getTranslatedText(
                                            context, 'Enter your email'),
                                        prefixIcon: Icon(Icons.email),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7), // Adjust radius as needed
                                          borderSide: BorderSide.none, // Removes the default underline
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: BorderSide(
                                            color: Colors.transparent, // Change color for focus effect
                                            width: 2, // Adjust thickness
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return L10n.getTranslatedText(
                                              context, 'Please enter an email');
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return L10n.getTranslatedText(
                                              context, 'Enter a valid email');
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(L10n.getTranslatedText(context,
                                        'Password'),
                                        style: TextStyle(fontSize: screenWidth * 0.043, color: Colors.black54, fontWeight: FontWeight.w700)),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AcademeTheme.notWhite,
                                        hintText: L10n.getTranslatedText(
                                            context, 'Enter your password'),
                                        prefixIcon: Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7), // Adjust radius as needed
                                          borderSide: BorderSide.none, // Removes the default underline
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          borderSide: BorderSide(
                                            color: Colors.transparent, // Change color for focus effect
                                            width: 2, // Adjust thickness
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return L10n.getTranslatedText(
                                              context, 'Please enter a password');
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
                                            L10n.getTranslatedText(
                                                context, 'Forgot Password?'),
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
                                                L10n.getTranslatedText(context, 'Log in'),
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
                                        Text(L10n.getTranslatedText(context, 'OR'),
                                            style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600, color: Colors.black54)),
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
                                          label: Text(L10n.getTranslatedText(
                                              context, 'Continue with Google'),
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
                                          L10n.getTranslatedText(
                                              context, 'Don\'t have an account?'),
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
                                            L10n.getTranslatedText(context, 'Signup'),
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
