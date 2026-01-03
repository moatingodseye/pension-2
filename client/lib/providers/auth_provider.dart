import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool loggedIn = false;
  bool isAdmin = false;

  Future<void> login(String username, String password) async {
    final res = await ApiService.post('login', {
      'username': username,
      'password': password,
    });
    if (res['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']); // ✅ changed: await added
      await ApiService.initToken(); // ✅ changed: await added

      loggedIn = true; // ✅ changed: set before notifyListeners
      isAdmin = res['isAdmin'] == true; // ✅ changed: set before notifyListeners

      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await ApiService.clearToken();

    loggedIn = false;
    isAdmin = false;
    notifyListeners();
  }
}
