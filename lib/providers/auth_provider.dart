import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Provides reactive authentication state to the widget tree.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService) {
    // Listen to auth state changes to keep UI in sync
    _authService.authStateChanges.listen((_) => notifyListeners());
  }

  // --- Getters ---

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _authService.isSignedIn;
  User? get user => _authService.currentUser;
  String? get displayName => _authService.displayName;
  String? get email => _authService.email;
  String? get photoUrl => _authService.photoUrl;

  // --- Actions ---

  /// Sign in with Google. Returns the User on success, null on cancel.
  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      return user;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out from Google and Firebase.
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
