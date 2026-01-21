import 'package:flutter/material.dart';
import 'package:shared/models/account.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

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
    
    log.info('Loading accounts (page: $page)');
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final offset = (page - 1) * limit;
      final res = await ApiService.getPaged('account?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      accounts = list.map((json) => Account.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? accounts.length;
      log.info('Loaded ${accounts.length} accounts');
      
    } catch (e) {
      log.severe('Error loading accounts: $e');
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
    log.info('Adding account: ${account.name}');
    try {
      await ApiService.post('account', account.toJson());
      await load();
      log.info('Account added successfully');
    } catch (e) {
      log.severe('Error adding account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Account account) async {
    if (account.id == null) return;
    log.info('Updating account: ${account.id}');
    try {
      await ApiService.put('account/${account.id}', account.toJson());
      await load();
      log.info('Account updated successfully');
    } catch (e) {
      log.severe('Error updating account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.info('Deleting account: $id');
    try {
      await ApiService.delete('account/$id');
      await load();
      log.info('Account deleted successfully');
    } catch (e) {
      log.severe('Error deleting account: $e');
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
