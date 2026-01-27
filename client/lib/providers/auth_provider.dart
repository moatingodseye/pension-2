import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/models/user.dart';
import '../services/apiService.dart';

class AuthProvider extends ChangeNotifier {
  bool loggedIn = false;
  bool isAdmin = false;
  User? user;

  Future<void> login(String username, String password) async {
    final res = await ApiService.post('login', {
      'username': username,
      'password': password,
    });
    if (res['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']); // ✅ changed: await added
      await ApiService.initToken(); // ✅ changed: await added
      int? id = int.tryParse(res['id'].toString());
      DateTime? dob = DateTime.tryParse(res['dob'].toString());
      user = User(id:id, username:username, dob:dob);

      loggedIn = true; 
      isAdmin = res['isAdmin'];// suddenly changed to boolean was int! == 1; 

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
