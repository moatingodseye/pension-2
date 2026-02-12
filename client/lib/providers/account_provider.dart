import 'package:flutter/material.dart';
import 'package:shared/models/account.dart';
import '../services/apiService.dart';
import '../services/apiException.dart';

import '../services/debugLogger.dart';

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
    
    glog.info('Loading accounts (page: $page)');
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final offset = (page - 1) * limit;
      final res = await ApiService.getPaged('account?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      accounts = list.map((json) => Account.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? accounts.length;
      glog.info('Loaded ${accounts.length} accounts');
      
    } catch (e) {
      glog.severe('Error loading accounts: $e');
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
    glog.info('Adding account: ${account.name}');
    try {
      await ApiService.post('account', account.toJson());
      await load();
      glog.info('Account added successfully');
    } catch (e) {
      glog.severe('Error adding account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Account account) async {
    if (account.id == null) return;
    glog.info('Updating account: ${account.id}');
    try {
      await ApiService.put('account/${account.id}', account.toJson());
      await load();
      glog.info('Account updated successfully');
    } catch (e) {
      glog.severe('Error updating account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    glog.info('Deleting account: $id');
    try {
      await ApiService.delete('account/$id');
      await load();
      glog.info('Account deleted successfully');
    } catch (e) {
      glog.severe('Error deleting account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
