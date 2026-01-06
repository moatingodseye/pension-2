import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataProvider extends ChangeNotifier {
  bool isLoading = false; // Flag for loading state
  List<dynamic> pensionPots = [];
  List<dynamic> drawdowns = [];
  Map<String, dynamic> statePension = {};
//  List<double> simulationResults = [];
//  Map<String, List<double>> simulationResults = {};
//  Map<String, dynamic>? simulationResults;
  List<dynamic> users = [];

  // ───────── Pension Pots ─────────

  Future<void> fetchPensionPots() async {
    isLoading = true; // Start loading
    notifyListeners();
    
    pensionPots = await ApiService.getList('pension_pots');
    
    isLoading = false; // Finished loading
    notifyListeners();
  }

  Future<void> addPensionPot(Map<String, dynamic> pot) async {
    final res = await ApiService.post('pension_pots', pot);
    if (res['success'] == true) {
      await fetchPensionPots();
    }
    notifyListeners();
  }

  Future<void> updatePensionPot(int id, Map<String, dynamic> updatedPot) async {
    final res = await ApiService.put('pension_pots/$id', updatedPot);
    if (res['success'] == true) {
      await fetchPensionPots();
    }
  }

  Future<void> deletePensionPot(int id) async {
    final res = await ApiService.delete('pension_pots/$id');
    if (res['success'] == true) {
      await fetchPensionPots();
    }
  }

  // ───────── Drawdowns ─────────

  Future<void> fetchDrawdowns() async {
    isLoading = true;
    notifyListeners();
    
    drawdowns = await ApiService.getList('drawdowns');
    isLoading = false;
    notifyListeners();
  }

  Future<void> addDrawdown(Map<String, dynamic> drawdown) async {
    final res = await ApiService.post('drawdowns', drawdown);
    if (res['success'] == true) {
      await fetchDrawdowns();
    }
  }

  Future<void> updateDrawdown(int id, Map<String, dynamic> update) async {
    final res = await ApiService.put('drawdowns/$id', update);
    if (res['success'] == true) {
      await fetchDrawdowns();
    }
  }

  Future<void> deleteDrawdown(int id) async {
    final res = await ApiService.delete('drawdowns/$id');
    if (res['success'] == true) {
      await fetchDrawdowns();
    }
  }

  // ───────── State Pension ─────────

  Future<void> fetchStatePension() async {
    final res = await ApiService.getOne('state_pension');
    statePension = res;
    notifyListeners();
  }

  Future<void> createStatePension(Map<String, dynamic> sp) async {
    final res = await ApiService.post('state_pension', sp);
    if (res['success'] == true) {
      await fetchStatePension();
    }
  }

  Future<void> updateStatePension(int id, Map<String,dynamic> sp) async {
    final res = await ApiService.put('state_pension/$id',sp);
    if (res['success']== true)
      await fetchStatePension();
  }

  // ───────── Simulation ─────────

  // Simulation results
  Map<String, dynamic> simulationResults = {};
  // Toggles: [sumPot, income, MonteCarlo, pot1, pot2, ...]
  List<bool> showLines = [];

  // Simulate function
  Future<void> simulate() async {
    final res = await ApiService.post('simulate', {});

    if (res['success'] == true && res['data'] is Map) {
      final data = res['data'];

      // Extract values
      List<double> sum = List<double>.from(data['sum'] ?? []);
      List<double> income = List<double>.from(data['income'] ?? []);
      List<List<double>> pots = (data['pots'] as List<dynamic>?)
              ?.map((p) => List<double>.from(p))
              .toList() ?? [];
      List<double> monteMin = List<double>.from(data['monte_min'] ?? []);
      List<double> monteMax = List<double>.from(data['monte_max'] ?? []);
      int startAge = data['age'];
      List<double> ages = [];//List<double>();// = List<double>.from(data['ages'] ?? []);

      if (ages.isEmpty) {
        for(int month = 0; month < data['count']; month++) {
          ages.add(startAge + month.toDouble());
        }
      }

      // Axis Min/Max Calculations
      double sumPotMin = 0.0;//sum.isNotEmpty ? sum.reduce((a, b) => a < b ? a : b) : 0.0;
      double sumPotMax = sum.isNotEmpty ? sum.reduce((a, b) => a > b ? a : b) : 2000000.0;
      double incomeMin = 0.0;//income.isNotEmpty ? income.reduce((a, b) => a < b ? a : b) : 0.0;
      double incomeMax = income.isNotEmpty ? income.reduce((a, b) => a > b ? a : b) : 50000.0;
      double xAxisMax = ages.isNotEmpty ? ages.last : 12.0;
      double xAxisMin = ages.isNotEmpty ? ages.first : 0.0;

      // Store results in simulationResults
      simulationResults = {
        'sum': sum,
        'income': income,
        'pots': pots,
        'monte_min': monteMin,
        'monte_max': monteMax,
        'ages': ages,
        'sumMin': sumPotMin,
        'sumMax': sumPotMax,
        'incomeMin': incomeMin,
        'incomeMax': incomeMax,
        'xAxisMin': xAxisMin,
        'xAxisMax': xAxisMax,
      };

      // Initialize showLines: sumPot + income + MC + individual pots
      showLines = List<bool>.filled(3 + pots.length, true);

      notifyListeners();
    }
  }

  // ───────── Admin Users ─────────

  Future<void> fetchUsers() async {
    users = await ApiService.getList('admin/users');
    notifyListeners();
  }

  Future<void> lockUser(int userId) async {
    final res =
        await ApiService.post('admin/lock_user', {'user_id': userId});
    if (res['success'] == true) {
      await fetchUsers();
    }
  }

  Future<void> unlockUser(int userId) async {
    final res =
        await ApiService.post('admin/unlock_user', {'user_id': userId});
    if (res['success'] == true) {
      await fetchUsers();
    }
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    final res = await ApiService.post('admin/reset_password', {
      'user_id': userId,
      'new_password': newPassword,
    });
    if (res['success'] == true) {
      await fetchUsers();
    }
  }

  // Update user details
  Future<void> updateUser(
    int userId,
    String username,
    String dob,
    String? password, // password can be null if not provided
    bool isAdmin,
    bool isLocked,
  ) async {
    // Prepare data to send to the backend
    final Map<String, dynamic> userData = {
      'username': username,
      'dob': dob,
      'is_admin': isAdmin ? 1 : 0,
      'locked': isLocked ? 1 : 0,
    };

    // If password is provided, include it in the update request
    if (password != null && password.isNotEmpty) {
      userData['password'] = password;
    }

    try {
      final response = await ApiService.put('admin/user/$userId', userData);

      if (response['success'] == true) {
        // If the update is successful, fetch the updated users
        await fetchUsers();
      } else {
        throw Exception('Failed to update user: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error updating user: ${e.toString()}');
    }
  }

  // Get a user's full details by ID (including DOB)
  Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final response = await ApiService.getOne('admin/user/$userId');
      return response;  // This should return user details including dob, is_admin, etc.
    } catch (e) {
      throw Exception('Error fetching user details: ${e.toString()}');
    }
  }  
}
