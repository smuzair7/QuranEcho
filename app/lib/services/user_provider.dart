import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _username;
  bool _isLoggedIn = false;

  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;

  void login(String username) {
    _username = username;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _username = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
