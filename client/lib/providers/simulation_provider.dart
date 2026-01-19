import 'package:flutter/material.dart';
import 'package:shared/models/simulation_result.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

class SimulationProvider extends ChangeNotifier {
  SimulationResult? result;
  bool isLoading = false;
  String? error;
  List<bool> showLines = [];

  Future<void> run() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await ApiService.post('simulate', {});
      result = SimulationResult.fromJson(res);
      
      // Reset showLines based on pots
      showLines = List<bool>.filled(3 + result!.pots.length, true);
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
  
  void toggleLine(int index) {
    if (index >= 0 && index < showLines.length) {
      showLines[index] = !showLines[index];
      notifyListeners();
    }
  }
}
