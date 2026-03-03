import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  
  // A cached role from the firestore user document. Default to patient.
  String? _cachedRole;
  String? get currentUserRole => _cachedRole ?? 'patient';

  /// Sign in with email and password.
  Future<String> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Fetch role from Firestore
      if (cred.user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          _cachedRole = data['role'] as String?;
        }
      }
      return _cachedRole ?? 'patient';
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed: ${e.code}';
      }
      throw AuthException(errorMessage);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Sign up a new user.
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? height,
    String? weight,
    String? caregiverName,
    String? caregiverEmail,
    String? phone,
    String? linkedPatientId,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (cred.user != null) {
        // Build the user profile object
        try {
          await _firestore.collection('users').doc(cred.user!.uid).set({
            'name': name,
            'email': email.trim(),
            'role': role,
            'height': height,
            'weight': weight,
            'caregiverName': caregiverName,
            'caregiverEmail': caregiverEmail,
            'phone': phone,
            'linkedPatientId': linkedPatientId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          // If Firestore write fails, delete the auth user
          debugPrint('Firestore error: $firestoreError');
          debugPrint('Firestore error type: ${firestoreError.runtimeType}');
          
          String errorMsg = 'Failed to create user profile';
          if (firestoreError is FirebaseException) {
            errorMsg = 'Firestore error: ${firestoreError.message}';
          } else {
            errorMsg = 'Database error: ${firestoreError.toString()}';
          }
          
          try {
            await cred.user!.delete();
          } catch (deleteError) {
            debugPrint('Failed to delete auth user: $deleteError');
          }
          
          throw AuthException(errorMsg);
        }
        _cachedRole = role;
      }
      return role;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed: ${e.code}';
      }
      throw AuthException(errorMessage);
    } catch (e) {
      debugPrint('Unexpected signup error: $e');
      String errorMsg = e.toString();
      if (errorMsg.isEmpty || errorMsg == 'Error') {
        errorMsg = 'An unexpected error occurred. Please try again.';
      }
      throw AuthException(errorMsg);
    }
  }

  /// Send password reset link
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Password reset failed');
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _cachedRole = null;
    await _auth.signOut();
  }

  /// Attempt biometric authentication (only available on mobile).
  Future<bool> attemptBiometric() async {
    if (kIsWeb) return false;
    return false;
  }

  /// Check if biometrics are available on this platform.
  bool get isBiometricAvailable => !kIsWeb;

  // --- Remember Me helpers ---
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
    await prefs.setBool('remember_me', true);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('remember_me', false);
  }

  Future<Map<String, String>?> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (!remember) return null;
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
