import 'package:flutter/material.dart';
import 'package:shared/models/transfer.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class TransferProvider extends ChangeNotifier {
  List<Transfer> transfers = [];
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
      final res = await ApiService.getPaged('transfer?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      transfers = list.map((json) => Transfer.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? transfers.length;
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
