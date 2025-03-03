import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String studentClass;
  final String photo_url;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.studentClass,
    required this.photo_url,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json["id"],
      email: json["email"],
      name: json["name"],
      studentClass: json["student_class"],
      photo_url: json["photo_url"],
    );
  }
}

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _baseUrl = "http://10.0.2.2:8001"; // Backend URL

  /// ✅ Sign up user via backend & store access token securely
  Future<(AppUser?, String?)> signUp(String email, String password, String name,
      String studentClass, String photo_url) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/users/signup"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "student_class": studentClass,
          "photo_url": photo_url,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // ✅ Extract and store token securely
        final String accessToken = responseData["access_token"];
        await _secureStorage.write(key: "access_token", value: accessToken);

        // ✅ Create AppUser object
        AppUser user = AppUser.fromJson(responseData);
        return (user, null); // ✅ Return AppUser object and no error
      } else {
        final errorData = jsonDecode(response.body);
        return (null, errorData["detail"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      return (null, "An unexpected error occurred: $e");
    }
  }

  /// ✅ Sign in existing user via backend & store access token
  Future<(AppUser?, String?)> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/api/users/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String userId = responseData["id"] ?? ""; // ✅ Handle null
        final String accessToken = responseData["access_token"] ?? "";
        final String name = responseData["name"] ?? "Unknown";
        final String userEmail = responseData["email"] ?? "";
        final String studentClass = responseData["student_class"] ?? "SELECT";
        final String photo_url = responseData["photo_url"] ??
            "https://www.w3schools.com/w3images/avatar2.png";

        // ✅ Store token securely
        await _secureStorage.write(key: "access_token", value: accessToken);

        // ✅ Store user details securely (optional)
        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: name);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: studentClass);
        await _secureStorage.write(key: "photo_url", value: photo_url);

        // ✅ Return the AppUser object with `id`
        return (
          AppUser(
            id: userId.isNotEmpty ? userId : "N/A", // ✅ Ensure non-null `id`
            name: name,
            email: userEmail,
            studentClass: studentClass,
            photo_url: photo_url,
          ),
          null
        );
      } else {
        return (null, "Login failed: ${response.body}");
      }
    } catch (e) {
      return (null, "An unexpected error occurred: $e");
    }
  }

  /// ✅ Google Sign-In (Using Backend)
  Future<(AppUser?, String?)> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (null, '❌ Google Sign-In canceled');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return (null, '❌ Google authentication failed');

      final String email = firebaseUser.email ?? "";
      final String name = firebaseUser.displayName ?? "Google User";
      final String photo_url = firebaseUser.photoURL ??
          "https://www.w3schools.com/w3images/avatar2.png"; // ✅ Default avatar URL

      if (email.isEmpty)
        return (null, '❌ Google authentication failed: Email not found');

      const String defaultPassword = "GOOGLE_AUTH_ACADEMe";
      const String defaultClass = "SELECT";

      // ✅ Check if user exists in backend
      final bool userExists = await checkIfUserExists(email);

      if (!userExists) {
        // ✅ Register user using ACADEMe-backend
        final (_, String? signupError) =
            await signUp(email, defaultPassword, name, defaultClass, photo_url);
        if (signupError != null) return (null, "❌ Signup failed: $signupError");
      }

      // ✅ Log in the user using backend
      final (_, String? loginError) = await signIn(email, defaultPassword);
      if (loginError != null) return (null, "❌ Login failed: $loginError");

      return (
        AppUser(
            id: firebaseUser.uid,
            email: email,
            name: name,
            studentClass: defaultClass,
            photo_url: photo_url),
        null
      );
    } catch (e) {
      return (null, "❌ An unexpected error occurred: $e");
    }
  }

  /// ✅ Check if user exists via backend
  Future<bool> checkIfUserExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/users/exists?email=$email"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData["exists"] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// ✅ Logout user and clear stored access token
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _secureStorage.delete(key: "access_token"); // ✅ Clear token
  }

  /// ✅ Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: "access_token");
  }

  /// ✅ Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    String? token = await getAccessToken();
    return token != null;
  }

  /// ✅ Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  /// ✅ Fetch user details from backend
  Future<Map<String, dynamic>?> getUserDetails() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/api/users/me"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
