import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock auth service that simulates Firebase Auth behavior.
/// When Firebase is configured, swap methods for real firebase_auth calls.
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._() {
    // Pre-seeded demo accounts
    _users['patient@demo.com'] = _UserRecord(
      name: 'Demo Patient',
      email: 'patient@demo.com',
      password: 'demo123',
      role: 'patient',
    );
    _users['caregiver@demo.com'] = _UserRecord(
      name: 'Dr. Sarah Chen',
      email: 'caregiver@demo.com',
      password: 'demo123',
      role: 'caregiver',
    );
  }

  final Map<String, _UserRecord> _users = {};
  _UserRecord? _currentUser;

  String? get currentUserName => _currentUser?.name;
  String? get currentUserRole => _currentUser?.role;
  bool get isLoggedIn => _currentUser != null;

  /// Sign in with email and password.
  /// Returns the user's role on success, throws on failure.
  Future<String> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    final user = _users[email.toLowerCase().trim()];
    if (user == null) throw AuthException('No account found with this email.');
    if (user.password != password) throw AuthException('Incorrect password.');
    _currentUser = user;
    return user.role;
  }

  /// Sign up a new user.
  /// Returns the user's role on success, throws on failure.
  Future<String> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.toLowerCase().trim();
    if (_users.containsKey(key)) {
      throw AuthException('An account with this email already exists.');
    }
    final user = _UserRecord(name: name, email: key, password: password, role: role);
    _users[key] = user;
    _currentUser = user;
    return role;
  }

  /// Send password reset link (mock).
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final key = email.toLowerCase().trim();
    if (!_users.containsKey(key)) {
      throw AuthException('No account found with this email.');
    }
    // In real Firebase: FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  /// Sign out.
  void signOut() {
    _currentUser = null;
  }

  /// Attempt biometric authentication (only available on mobile).
  Future<bool> attemptBiometric() async {
    if (kIsWeb) return false;
    // On mobile, use local_auth here:
    // final localAuth = LocalAuthentication();
    // return await localAuth.authenticate(localizedReason: 'Sign in with biometrics');
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

class _UserRecord {
  final String name;
  final String email;
  final String password;
  final String role;
  _UserRecord({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}
