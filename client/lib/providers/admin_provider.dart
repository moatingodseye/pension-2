import 'package:flutter/material.dart';
import 'package:shared/models/user.dart';
import '../services/apiService.dart';
import '../services/apiException.dart';

class AdminProvider extends ChangeNotifier {
  List<User> _user = [];
  bool isLoading = false;
  String? error;

  List<User> get() {
    return _user;
  }

  Future<void> loadUsers() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final list = await ApiService.getList('user');
      _user = list.map((json) => User.fromJson(json)).toList();
    } catch (e) {
       if (e is apiException) {
         error = e.body;
       } else {
         error = e.toString();
       }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> lockUser(int userId) async {
    final res = await ApiService.post('admin/lock/$userId', {});
    if (res['success'] == true) await loadUsers();
  }

  Future<void> unlockUser(int userId) async {
    final res = await ApiService.post('admin/unlock/$userId',{});
    if (res['success'] == true) await loadUsers();
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    final res = await ApiService.post('admin/reset/$userId', {
      'new_password': newPassword,
    });
    if (res['success'] == true) await loadUsers();
  }

  Future<void> updateUser(User user) async {
    if (user.id == null) return;
    try {
      await ApiService.put('user/${user.id}', user.toJson());
      await loadUsers();
    } catch (e) {
      if (e is apiException) {
        error = e.body;
      } else {
        error = e.toString();
      }
      rethrow;
    }
  }
}
