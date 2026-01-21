import 'package:flutter/material.dart';
import 'package:shared/models/simulation_result.dart';
import '../services/apiService.dart';
import '../services/aprException.dart';

import 'package:shared/models/account.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import '../services/simulation_service.dart';

import '../services/debugLogger.dart';

class SimulationProvider extends ChangeNotifier {
  SimulationResult? result;
  bool isLoading = false;
  String? error;
  List<bool> showLines = [];

  Future<void> run({
    double volatility = 0.12, 
    double rateAdjustment = 0.0,
    // Pass data needed for client-side viz
    required List<Account> accounts,
    required List<Income> incomes,
    required List<Outgoing> outgoings,
    required List<Transfer> transfers,
    required DateTime dob, // Needed for ages
  }) async {
    log.info('Starting hybrid simulation (volatility: $volatility, adjustment: $rateAdjustment)');
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // 1. Server Run (Official Data)
      log.info('Fetching official simulation from server...');
      final res = await ApiService.post('simulate', {
        'volatility': volatility,
        'rate_adjustment': rateAdjustment,
      });
      final serverResult = SimulationResult.fromJson(res);
      log.info('Server simulation received.');

      // 2. Client Run (Visual Cloud)
      log.info('Running client-side Monte Carlo (${accounts.length} accounts)...');
      final clientResult = SimulationService.run(
        accounts: accounts,
        incomes: incomes,
        outgoings: outgoings,
        transfers: transfers,
        dob: dob,
        volatility: volatility,
        rateAdjustment: rateAdjustment,
      );
      log.info('Client-side simulation completed.');

      // 3. Merge
      // We keep server stats but overlay client monte paths
      result = SimulationResult(
        sumPotMin: serverResult.sumPotMin,
        sumPotMax: serverResult.sumPotMax, 
        incomeMin: serverResult.incomeMin,
        incomeMax: serverResult.incomeMax, 
        xAxisMin: serverResult.xAxisMin, 
        xAxisMax: serverResult.xAxisMax, 
        sum: serverResult.sum, 
        income: serverResult.income, 
        pots: serverResult.pots, 
        monteMin: serverResult.monteMin, 
        monteMax: serverResult.monteMax, 
        ages: serverResult.ages,
        montePaths: clientResult.montePaths, // The cloud!
      );
      
      // Reset showLines based on pots
      showLines = List<bool>.filled(3 + result!.pots.length, true);
    } catch (e) {
      log.severe('Simulation failed: $e');
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
