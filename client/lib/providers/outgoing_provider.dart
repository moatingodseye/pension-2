import 'package:flutter/material.dart';
import 'package:shared/models/outgoing.dart';
import '../services/apiService.dart';
import '../services/apiException.dart';

class OutgoingProvider extends ChangeNotifier {
  List<Outgoing> outgoings = [];
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
      final res = await ApiService.getPaged('outgoing?limit=$limit&offset=$offset');
      
      final list = res['data'] as List;
      outgoings = list.map((json) => Outgoing.fromJson(json)).toList();
      totalCount = res['count'] as int? ?? outgoings.length;
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

  Future<void> add(Outgoing item) async {
    try {
      await ApiService.post('outgoing', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Outgoing item) async {
    if (item.id == null) return;
    try {
      await ApiService.put('outgoing/${item.id}', item.toJson());
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiService.delete('outgoing/$id');
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
