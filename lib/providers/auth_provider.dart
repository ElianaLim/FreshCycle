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
        final deviceId = await DB.getDeviceId();
        await DB.client.rpc('claim_guest_data', params: {
          'p_device_id': deviceId,
          'p_user_id': _user!.id,
        });
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
        final deviceId = await DB.getDeviceId();
        await DB.client.rpc('claim_guest_data', params: {
          'p_device_id': deviceId,
          'p_user_id': _user!.id,
        });
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

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? initials,
    String? phoneNumber,
  }) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await DB.updateProfile(
        userId: _user!.id,
        name: name,
        initials: initials,
        phoneNumber: phoneNumber,
      );

      if (success) {
        // Update local user object
        _user = User(
          id: _user!.id,
          name: name ?? _user!.name,
          email: _user!.email,
          initials: initials ?? _user!.initials,
          profilePictureUrl: _user!.profilePictureUrl,
          number: phoneNumber ?? _user!.number,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Update profile error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await DB.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Current password is incorrect.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Change password error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}