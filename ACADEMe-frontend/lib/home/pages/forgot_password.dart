import 'package:flutter/material.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _sendOtp() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(L10n.getTranslatedText(context, 'Please enter your email'));
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(L10n.getTranslatedText(context, 'Enter a valid email'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (success, message) = await _authService.sendForgotPasswordOTP(email);

      if (success) {
        setState(() => _isOtpSent = true);
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'OTP sent successfully'));
      } else {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Failed to send OTP'));
      }
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    final String otp = _otpController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (otp.isEmpty) {
      _showSnackBar(L10n.getTranslatedText(context, 'Please enter the OTP'));
      return;
    }

    if (otp.length != 6) {
      _showSnackBar(L10n.getTranslatedText(context, 'OTP must be 6 digits'));
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar(L10n.getTranslatedText(context, 'Please enter new password'));
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar(L10n.getTranslatedText(context, 'Password must be at least 6 characters'));
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar(L10n.getTranslatedText(context, 'Passwords do not match'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (success, message) = await _authService.resetPasswordWithOTP(email, otp, newPassword);

      if (success) {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Password reset successfully'));
        Navigator.pop(context);
      } else {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Failed to reset password'));
      }
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resendOtp() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
    });
    _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.getTranslatedText(context, 'Forgot Password?'),
                                style: TextStyle(
                                  fontSize: width * 0.08,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                _isOtpSent
                                    ? L10n.getTranslatedText(context, 'Enter the OTP sent to your email')
                                    : L10n.getTranslatedText(context, 'Enter your email to reset password'),
                                style: TextStyle(
                                  fontSize: width * 0.047,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.03),

                              if (!_isOtpSent) ...[
                                _buildEmailSection(width, height),
                                SizedBox(height: height * 0.02),
                                _buildSendOtpButton(width),
                              ] else ...[
                                _buildOtpSection(width, height),
                                SizedBox(height: height * 0.02),
                                _buildPasswordSection(width, height),
                                SizedBox(height: height * 0.02),
                                _buildResetButton(width),
                              ],

                              SizedBox(height: height * 0.03),
                              _buildLoginLink(width),
                            ],
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

  Widget _buildEmailSection(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            hintText: L10n.getTranslatedText(context, 'Enter your email'),
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendOtpButton(double width) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow[600],
          minimumSize: Size(double.infinity, width * 0.11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 193, 191, 191)),
        )
            : Text(
          L10n.getTranslatedText(context, 'Send OTP'),
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.getTranslatedText(context, 'OTP'),
          style: TextStyle(
            fontSize: width * 0.043,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            filled: true,
            fillColor: AcademeTheme.notWhite,
            hintText: L10n.getTranslatedText(context, 'Enter 6-digit OTP'),
            prefixIcon: const Icon(Icons.security),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resendOtp,
            child: Text(
              L10n.getTranslatedText(context, 'Resend OTP?'),
              style: TextStyle(
                color: AcademeTheme.appColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.getTranslatedText(context, 'New Password'),
          style: TextStyle(
            fontSize: width * 0.043,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: AcademeTheme.notWhite,
            hintText: L10n.getTranslatedText(context, 'Enter new password'),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: height * 0.02),
        Text(
          L10n.getTranslatedText(context, 'Confirm Password'),
          style: TextStyle(
            fontSize: width * 0.043,
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: AcademeTheme.notWhite,
            hintText: L10n.getTranslatedText(context, 'Confirm new password'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(double width) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _resetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow[600],
          minimumSize: Size(double.infinity, width * 0.11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 193, 191, 191)),
        )
            : Text(
          L10n.getTranslatedText(context, 'Reset Password'),
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          L10n.getTranslatedText(context, 'Remembered your password?'),
          style: TextStyle(
            fontSize: width * 0.038,
            color: Colors.black54,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            L10n.getTranslatedText(context, 'login'),
            style: TextStyle(
              fontSize: width * 0.038,
              fontWeight: FontWeight.w500,
              color: AcademeTheme.appColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}