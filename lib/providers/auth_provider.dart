import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../data/db.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check for existing session on app start
  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = DB.getCurrentUser();
      if (currentUser != null) {
        final profile = await DB.getProfile(currentUser['id']);
        if (profile != null) {
          _user = User.fromMap(profile);
        }
      }
    } catch (e) {
      print('Session check error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String number,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DB.registerUser(
        name: name,
        email: email,
        password: password,
        number: number,
      );

      if (result != null) {
        _user = User.fromMap(result);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DB.loginUser(
        email: email,
        password: password,
      );

      if (result != null) {
        _user = User.fromMap(result);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await DB.logout();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}