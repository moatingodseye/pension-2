import 'package:flutter/material.dart';
import 'package:shared/models/account.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> accounts = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final list = await ApiService.getList('account');
      accounts = list.map((json) => Account.fromJson(json)).toList();
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

  Future<void> add(Account account) async {
    try {
      await ApiService.post('account', account.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Account account) async {
    if (account.id == null) return;
    try {
      await ApiService.put('account/${account.id}', account.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiService.delete('account/$id');
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
