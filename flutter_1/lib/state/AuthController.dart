import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  String? token;
  String? username;
  String? userType;

  void setAuth({required String token, String? username, String? userType}) {
    this.token = token;
    this.username = username;
    this.userType = userType;
    notifyListeners();
  }

  void clearAuth() {
    token = null;
    username = null;
    userType = null;
    notifyListeners();
  }

  bool get isLoggedIn => token != null;
}
