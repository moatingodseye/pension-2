import 'package:flutter/material.dart';
import 'package:shared/models/income.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class IncomeProvider extends ChangeNotifier {
  List<Income> incomes = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final list = await ApiService.getList('income');
      incomes = list.map((json) => Income.fromJson(json)).toList();
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
