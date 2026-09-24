import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../errors/app_exception.dart';
import '../models/student.dart';
import '../constants/enums.dart';
import 'dart:async';

/// Provides the FirebaseAuth instance.
final firebaseAuthProvider = Provider<auth.FirebaseAuth>((ref) {
  return auth.FirebaseAuth.instance;
});

/// Provides the authentication service.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

/// Stream of the current authentication state.
final authStateProvider = StreamProvider<auth.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Authentication Service handling Firebase Auth operations.
class AuthService {
  AuthService(this._auth);

  final auth.FirebaseAuth _auth;

  // Google OAuth 2.0 Web Client ID from google-services.json
  static const String _webClientId =
      '1084970177493-t1gnoam3cddjgodpbol06l22nio9kb8b.apps.googleusercontent.com';

  /// Current user.
  auth.User? get currentUser => _auth.currentUser;

  /// Sign in with Google (Authenticates user without creating dummy profiles)
  Future<auth.UserCredential> signInWithGoogle() async {
    try {
      auth.UserCredential userCredential;

      if (kIsWeb) {
        // Native Firebase Auth popup for Web browsers
        final googleProvider = auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn(
          serverClientId: _webClientId,
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const AppException('Sign in was cancelled.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final auth.OAuthCredential credential = auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user != null && user.email != null) {
        // If an existing student record in Firestore matches this email, link the UID
        await _checkAndLinkExistingEmail(user.uid, user.email!);
      }

      return userCredential;
    } on auth.FirebaseAuthException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Google Sign-In failed: $e');
    }
  }

  /// If a student document with this email already exists, link the auth UID
  Future<void> _checkAndLinkExistingEmail(String uid, String email) async {
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection('students').where('email', isEqualTo: email.toLowerCase().trim()).limit(1).get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        if (doc.data()['linkedUid'] == null) {
          await doc.reference.update({
            'linkedUid': uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {}
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (e) {
      throw const AppException('Failed to sign out. Please try again.');
    }
  }

  /// Sign in with email and password.
  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on auth.FirebaseAuthException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('An unexpected error occurred during sign in.');
    }
  }

  /// Sign in with custom token.
  Future<auth.UserCredential> signInWithCustomToken(String token) async {
    try {
      return await _auth.signInWithCustomToken(token);
    } on auth.FirebaseAuthException catch (e) {
      throw ErrorMapper.fromFirebaseCode(e.code);
    } catch (e) {
      throw const AppException('Failed to sign in with custom token.');
    }
  }
}

