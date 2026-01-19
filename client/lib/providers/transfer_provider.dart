import 'package:flutter/material.dart';
import 'package:shared/models/transfer.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class TransferProvider extends ChangeNotifier {
  List<Transfer> transfers = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final list = await ApiService.getList('transfer');
      transfers = list.map((json) => Transfer.fromJson(json)).toList();
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

  Future<void> add(Transfer item) async {
    try {
      await ApiService.post('transfer', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Transfer item) async {
    if (item.id == null) return;
    try {
      await ApiService.put('transfer/${item.id}', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiService.delete('transfer/$id');
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
