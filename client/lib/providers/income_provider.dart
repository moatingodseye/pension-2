import 'package:flutter/material.dart';
import 'package:shared/models/income.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class IncomeProvider extends ChangeNotifier {
  List<Income> incomes = [];
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
      final res = await ApiService.getPaged('income?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      incomes = list.map((json) => Income.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? incomes.length;
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

  Future<void> add(Income item) async {
    try {
      await ApiService.post('income', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Income item) async {
    if (item.id == null) return;
    try {
      await ApiService.put('income/${item.id}', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiService.delete('income/$id');
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
