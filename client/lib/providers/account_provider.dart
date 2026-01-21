import 'package:flutter/material.dart';
import 'package:shared/models/account.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class AccountProvider extends ChangeNotifier {
  List<Account> accounts = [];
  bool isLoading = false;
  String? error;
  
  // Pagination
  int page = 1;
  int limit = 20;
  int totalCount = 0;

  Future<void> load({int? newPage}) async {
    if (newPage != null) page = newPage;
    
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final offset = (page - 1) * limit;
      final res = await ApiService.getPaged('account?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      accounts = list.map((json) => Account.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? accounts.length;
      
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

  void setPage(int p) {
     load(newPage: p);
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
