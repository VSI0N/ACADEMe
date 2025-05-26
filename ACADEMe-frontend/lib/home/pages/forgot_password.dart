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
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isSmallScreen = screenSize.width < 600;
    final isVerySmallScreen = screenSize.width < 400;

    // Responsive dimensions
    final horizontalPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 30.0);
    final cardPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 30.0);
    final logoHeight = isVerySmallScreen ? 120.0 : (isSmallScreen ? 180.0 : 250.0);
    final headerFontSize = isVerySmallScreen ? 24.0 : (isSmallScreen ? 28.0 : 30.0);
    final descriptionFontSize = isVerySmallScreen ? 14.0 : 16.0;
    final buttonHeight = isVerySmallScreen ? 45.0 : 50.0;
    final topPadding = MediaQuery.of(context).padding.top + (isVerySmallScreen ? 20.0 : 40.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: isVerySmallScreen ? 10.0 : 20.0,
                      bottom: keyboardHeight > 0 ? 20.0 : 30.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Section - Flexible to allow shrinking
                        if (!isVerySmallScreen || keyboardHeight == 0) ...[
                          SizedBox(height: isVerySmallScreen ? 10.0 : 20.0),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? 200 : 300,
                              maxHeight: logoHeight,
                            ),
                            child: Image.asset(
                              'assets/academe/academe_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: isVerySmallScreen ? 20.0 : 30.0),
                        ] else ...[
                          const SizedBox(height: 10.0),
                        ],

                        // Main Card
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 500),
                            decoration: BoxDecoration(
                              color: AcademeTheme.white,
                              boxShadow: isVerySmallScreen
                                  ? [
                                const BoxShadow(
                                  offset: Offset(0, 2),
                                  color: Colors.grey,
                                  blurRadius: 6,
                                )
                              ]
                                  : [
                                const BoxShadow(
                                  offset: Offset(1, 1),
                                  color: Colors.grey,
                                  blurRadius: 10,
                                )
                              ],
                              borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 10),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Text(
                                    L10n.getTranslatedText(context, 'Forgot Password?'),
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isOtpSent
                                        ? L10n.getTranslatedText(context, 'Enter the OTP sent to your email and create a new password.')
                                        : L10n.getTranslatedText(context, 'No worries! Enter your email below and we\'ll send you an OTP.'),
                                    style: TextStyle(
                                      fontSize: descriptionFontSize,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 20.0 : 30.0),

                                  // Email Field
                                  _buildLabelText(L10n.getTranslatedText(context, 'Email'), isVerySmallScreen),
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !_isOtpSent,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: _isOtpSent ? Colors.grey[100] : AcademeTheme.notWhite,
                                      labelText: L10n.getTranslatedText(context, 'Email'),
                                      hintText: L10n.getTranslatedText(context, 'Enter your email'),
                                      prefixIcon: Icon(Icons.email, size: isVerySmallScreen ? 20 : 24),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isVerySmallScreen ? 12 : 16,
                                        vertical: isVerySmallScreen ? 14 : 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 16.0 : 20.0),

                                  // Send OTP Button (shown only when OTP not sent)
                                  if (!_isOtpSent) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _sendOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellow[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(isVerySmallScreen ? 25 : 30),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                          height: isVerySmallScreen ? 20 : 24,
                                          width: isVerySmallScreen ? 20 : 24,
                                          child: const CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : Text(
                                          L10n.getTranslatedText(context, 'Send OTP'),
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 16.0 : 18.0,
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
                                    _buildLabelText(L10n.getTranslatedText(context, 'OTP'), isVerySmallScreen),
                                    TextFormField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AcademeTheme.notWhite,
                                        labelText: L10n.getTranslatedText(context, 'Enter OTP'),
                                        hintText: L10n.getTranslatedText(context, '6-digit OTP'),
                                        prefixIcon: Icon(Icons.security, size: isVerySmallScreen ? 20 : 24),
                                        counterText: '',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isVerySmallScreen ? 12 : 16,
                                          vertical: isVerySmallScreen ? 14 : 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Resend OTP
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _resendOtp,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isVerySmallScreen ? 8 : 12,
                                            vertical: isVerySmallScreen ? 4 : 8,
                                          ),
                                        ),
                                        child: Text(
                                          L10n.getTranslatedText(context, 'Resend OTP'),
                                          style: TextStyle(
                                            color: AcademeTheme.appColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: isVerySmallScreen ? 14.0 : 16.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // New Password Field
                                    _buildLabelText(L10n.getTranslatedText(context, 'New Password'), isVerySmallScreen),
                                    TextFormField(
                                      controller: _newPasswordController,
                                      obscureText: _obscureNewPassword,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AcademeTheme.notWhite,
                                        labelText: L10n.getTranslatedText(context, 'New Password'),
                                        hintText: L10n.getTranslatedText(context, 'Enter new password'),
                                        prefixIcon: Icon(Icons.lock, size: isVerySmallScreen ? 20 : 24),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                                            size: isVerySmallScreen ? 20 : 24,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureNewPassword = !_obscureNewPassword;
                                            });
                                          },
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isVerySmallScreen ? 12 : 16,
                                          vertical: isVerySmallScreen ? 14 : 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 10),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 16.0 : 20.0),

                                    // Confirm Password Field
                                    _buildLabelText(L10n.getTranslatedText(context, 'Confirm Password'), isVerySmallScreen),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AcademeTheme.notWhite,
                                        labelText: L10n.getTranslatedText(context, 'Confirm Password'),
                                        hintText: L10n.getTranslatedText(context, 'Confirm new password'),
                                        prefixIcon: Icon(Icons.lock_outline, size: isVerySmallScreen ? 20 : 24),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                            size: isVerySmallScreen ? 20 : 24,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: isVerySmallScreen ? 12 : 16,
                                          vertical: isVerySmallScreen ? 14 : 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 10),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 20.0 : 30.0),

                                    // Reset Password Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellow[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(isVerySmallScreen ? 25 : 30),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                          height: isVerySmallScreen ? 20 : 24,
                                          width: isVerySmallScreen ? 20 : 24,
                                          child: const CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : Text(
                                          L10n.getTranslatedText(context, 'Reset Password'),
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 16.0 : 18.0,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: isVerySmallScreen ? 16.0 : 20.0),

                                  // Back to Login
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        L10n.getTranslatedText(context, 'Remembered your password?'),
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 14.0 : 16.0,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isVerySmallScreen ? 4 : 8,
                                            vertical: isVerySmallScreen ? 0 : 4,
                                          ),
                                        ),
                                        child: Text(
                                          L10n.getTranslatedText(context, 'login'),
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 14.0 : 16.0,
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
                        ),

                        // Bottom padding
                        SizedBox(height: keyboardHeight > 0 ? 10.0 : 20.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabelText(String text, bool isVerySmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isVerySmallScreen ? 14.0 : 16.0,
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
