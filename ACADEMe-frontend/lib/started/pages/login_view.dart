import 'package:ACADEMe/started/pages/signup_view.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../../academe_theme.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../home/auth/role.dart';
import '../../home/pages/bottom_nav.dart';
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

  /// Shows a snackbar message
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Handles manual login
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        _showSnackBar(L10n.getTranslatedText(
            context, '⚠️ Please enter valid credentials'));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (user, errorMessage) = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) {
        return; // Ensure widget is still active before using context
      }
      if (errorMessage != null) {
        _showSnackBar(errorMessage);
        return;
      }

      if (user != null) {
        // Store user info
        await _secureStorage.write(key: "user_id", value: user.id);
        await _secureStorage.write(key: "user_name", value: user.name);
        await _secureStorage.write(key: "user_email", value: user.email);
        await _secureStorage.write(
            key: "student_class", value: user.studentClass);
        await _secureStorage.write(key: "photo_url", value: user.photoUrl);

        // Store credentials
        await _secureStorage.write(
            key: 'email', value: _emailController.text.trim());
        await _secureStorage.write(
            key: 'password', value: _passwordController.text.trim());

        if (mounted) {
          _showSnackBar(L10n.getTranslatedText(context, '✅ Login successful!'));
        }

        // Fetch user role
        await UserRoleManager().fetchUserRole(user.email);
        bool isAdmin = UserRoleManager().isAdmin;

        if (!mounted) return; // Ensure the widget is still active

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNav(isAdmin: isAdmin),
          ),
        );
      } else {
        if (mounted) {
          _showSnackBar(L10n.getTranslatedText(
              context, '❌ Login failed. Please try again.'));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      _showSnackBar(L10n.getTranslatedText(context,
          'Google Sign-In is not available yet. Please log in manually.'));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: height * 0.0),
                        Image.asset(
                          'assets/academe/academe_logo.png',
                          height: constraints.maxHeight * 0.23,
                        ),
                        Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: AcademeTheme.white,
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(1, 1),
                                color: Colors.grey,
                                blurRadius: 10,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  L10n.getTranslatedText(context, 'Hello'),
                                  style: TextStyle(
                                    fontSize: width * 0.08,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  L10n.getTranslatedText(
                                      context, 'Welcome back'),
                                  style: TextStyle(
                                    fontSize: width * 0.047,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.02),
                                Text(
                                  L10n.getTranslatedText(context, 'Email'),
                                  style: TextStyle(
                                    fontSize: width * 0.043,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AcademeTheme.notWhite,
                                    hintText: L10n.getTranslatedText(
                                        context, 'Enter your email'),
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return L10n.getTranslatedText(
                                          context, 'Please enter an email');
                                    }
                                    if (!RegExp(
                                            r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return L10n.getTranslatedText(
                                          context, 'Enter a valid email');
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: height * 0.02),
                                Text(
                                  L10n.getTranslatedText(context, 'Password'),
                                  style: TextStyle(
                                    fontSize: width * 0.043,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AcademeTheme.notWhite,
                                    hintText: L10n.getTranslatedText(
                                        context, 'Enter your password'),
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                        width: 2,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ForgotPasswordPage()),
                                        );
                                      },
                                      child: Text(
                                        L10n.getTranslatedText(
                                            context, 'Forgot Password?'),
                                        style: TextStyle(
                                          color: AcademeTheme.appColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 1),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.yellow[600],
                                        minimumSize:
                                            Size(double.infinity, width * 0.11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color.fromARGB(
                                                          255, 193, 191, 191)),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/icons/house_door.png',
                                                  height: 24,
                                                  width: 24,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  L10n.getTranslatedText(
                                                      context, 'Log in'),
                                                  style: TextStyle(
                                                    fontSize: width * 0.045,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.01),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      L10n.getTranslatedText(context, 'OR'),
                                      style: TextStyle(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 1),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isGoogleLoading
                                          ? null
                                          : _signInWithGoogle,
                                      icon: _isGoogleLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 7),
                                              child: Image.asset(
                                                  'assets/icons/google_icon.png',
                                                  height: 22),
                                            ),
                                      label: Text(
                                        L10n.getTranslatedText(
                                            context, 'Continue with Google'),
                                        style: TextStyle(
                                          fontSize: width * 0.045,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.black,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        minimumSize:
                                            Size(double.infinity, width * 0.11),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: height * 0.04),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      L10n.getTranslatedText(
                                          context, 'Don\'t have an account?'),
                                      style: TextStyle(
                                        fontSize: width * 0.038,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignUpView()),
                                        );
                                      },
                                      child: Text(
                                        L10n.getTranslatedText(
                                            context, 'Signup'),
                                        style: TextStyle(
                                          fontSize: width * 0.038,
                                          fontWeight: FontWeight.w500,
                                          color: AcademeTheme.appColor,
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
          ),
        ],
      ),
    );
  }
}
