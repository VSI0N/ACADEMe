import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up user and store their details in Firestore
  Future<(User?, String?)> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        return (null, 'Signup failed. Please try again');
      }

      // Store user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'name': name,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return (user, null); // Successful signup
    } on FirebaseAuthException catch (e) {
      return (null, _getSignupErrorMessage(e.code));
    } on FirebaseException catch (e) {
      return (null, 'Database error: ${e.message}');
    } catch (e) {
      return (null, 'An unexpected error occurred: $e');
    }
  }

  /// Sign in existing user
  Future<(User?, String?)> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        return (null, 'Login failed. Please try again');
      }

      return (user, null); // Successful login
    } on FirebaseAuthException catch (e) {
      return (null, _getSignInErrorMessage(e.code));
    } on FirebaseException catch (e) {
      return (null, 'Database error: ${e.message}');
    } catch (e) {
      return (null, 'An unexpected error occurred: $e');
    }
  }

  /// Returns a user-friendly error message for signup failures
  String _getSignupErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Signup failed. Please try again';
    }
  }

  /// Returns a user-friendly error message for login failures
  String _getSignInErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later';
      default:
        return 'Login failed. Please try again';
    }
  }
}
