import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  /// Sign in with Google
  Future<(User?, String?)> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (null, 'Google sign-in cancelled');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user == null) {
        return (null, 'Google sign-in failed');
      }

      // Store user data in Firestore (if it's a new user)
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName,
          'uid': user.uid,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return (user, null); // Successful Google sign-in
    } on FirebaseAuthException catch (e) {
      return (null, 'Google sign-in error: ${e.message}');
    } on FirebaseException catch (e) {
      return (null, 'Database error: ${e.message}');
    } catch (e) {
      return (null, 'An unexpected error occurred: $e');
    }
  }

  /// Sign out user (works for both email/password and Google sign-in)
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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
