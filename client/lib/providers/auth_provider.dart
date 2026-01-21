import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apiService.dart';

class AuthProvider extends ChangeNotifier {
  bool loggedIn = false;
  bool isAdmin = false;
  DateTime? dob;

  Future<void> login(String username, String password) async {
    final res = await ApiService.post('login', {
      'username': username,
      'password': password,
    });
    if (res['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']); // ✅ changed: await added
      await ApiService.initToken(); // ✅ changed: await added

      loggedIn = true; 
      isAdmin = res['isAdmin'] == 1; 
      if (res['dob'] != null) {
        dob = DateTime.tryParse(res['dob'].toString());
      }

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
