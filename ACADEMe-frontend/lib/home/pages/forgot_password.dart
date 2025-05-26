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

    setState(() {
      _isLoading = true;
    });

    try {
      final (success, message) = await _authService.sendForgotPasswordOTP(email);

      if (success) {
        setState(() {
          _isOtpSent = true;
        });
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'OTP sent successfully'));
      } else {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Failed to send OTP'));
      }
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    final String otp = _otpController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Validation
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

    setState(() {
      _isLoading = true;
    });

    try {
      final (success, message) = await _authService.resetPasswordWithOTP(email, otp, newPassword);

      if (success) {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Password reset successfully'));
        // Navigate back to login after successful reset
        Navigator.pop(context);
      } else {
        _showSnackBar(message ?? L10n.getTranslatedText(context, 'Failed to reset password'));
      }
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50, top: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  child: Image.asset(
                    'assets/academe/academe_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: BoxDecoration(
                  color: AcademeTheme.white,
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(1, 1),
                      color: Colors.grey,
                      blurRadius: 10,
                    )
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        L10n.getTranslatedText(context, 'Forgot Password?'),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOtpSent
                            ? L10n.getTranslatedText(context, 'Enter the OTP sent to your email and create a new password.')
                            : L10n.getTranslatedText(context, 'No worries! Enter your email below and we\'ll send you an OTP.'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      _buildLabelText(L10n.getTranslatedText(context, 'Email')),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isOtpSent, // Disable after OTP is sent
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isOtpSent ? Colors.grey[100] : AcademeTheme.notWhite,
                          labelText: L10n.getTranslatedText(context, 'Email'),
                          hintText: L10n.getTranslatedText(context, 'Enter your email'),
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Send OTP Button (shown only when OTP not sent)
                      if (!_isOtpSent) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[600],
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                              L10n.getTranslatedText(context, 'Send OTP'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // OTP and Password Fields (shown after OTP is sent)
                      if (_isOtpSent) ...[
                        // OTP Field
                        _buildLabelText(L10n.getTranslatedText(context, 'OTP')),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText: L10n.getTranslatedText(context, 'Enter OTP'),
                            hintText: L10n.getTranslatedText(context, '6-digit OTP'),
                            prefixIcon: const Icon(Icons.security),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Resend OTP
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _resendOtp,
                            child: Text(
                              L10n.getTranslatedText(context, 'Resend OTP'),
                              style: TextStyle(
                                color: AcademeTheme.appColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // New Password Field
                        _buildLabelText(L10n.getTranslatedText(context, 'New Password')),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText: L10n.getTranslatedText(context, 'New Password'),
                            hintText: L10n.getTranslatedText(context, 'Enter new password'),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        _buildLabelText(L10n.getTranslatedText(context, 'Confirm Password')),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AcademeTheme.notWhite,
                            labelText: L10n.getTranslatedText(context, 'Confirm Password'),
                            hintText: L10n.getTranslatedText(context, 'Confirm new password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Reset Password Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[600],
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                              L10n.getTranslatedText(context, 'Reset Password'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            L10n.getTranslatedText(context, 'Remembered your password?'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              L10n.getTranslatedText(context, 'login'),
                              style: TextStyle(
                                fontSize: 16,
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
      ),
    );
  }

  Widget _buildLabelText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
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