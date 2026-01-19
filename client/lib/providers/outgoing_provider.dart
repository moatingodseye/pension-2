import 'package:flutter/material.dart';
import 'package:shared/models/outgoing.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class OutgoingProvider extends ChangeNotifier {
  List<Outgoing> outgoings = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final list = await ApiService.getList('outgoing');
      outgoings = list.map((json) => Outgoing.fromJson(json)).toList();
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
