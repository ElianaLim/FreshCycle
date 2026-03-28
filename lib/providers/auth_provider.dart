import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void login() {
    _user = User.sampleUser;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}