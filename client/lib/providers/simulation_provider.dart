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
  List<bool> showList = [];

  Future<void> run({
    double volatility = 0.12, 
    double rateAdjustment = 0.0,
    // Pass data needed for client-side viz
    required List<Account> accountList,
    required List<Income> incomeList,
    required List<Outgoing> outgoingList,
    required List<Transfer> transferList,
    required DateTime dob, // Needed for ageList
  }) async {
    glog.info('Starting hybrid simulation (volatility: $volatility, adjustment: $rateAdjustment)');
    SimulationService sim = new SimulationService();
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // 1. Server Run (Official Data)
      glog.info('Fetching official simulation from server...');
      final res = await ApiService.post('simulate', {
        'volatility': volatility,
        'rate_adjustment': rateAdjustment,
      });
      final serverResult = SimulationResult.fromJson(res);
      glog.info('Server simulation received.');

      // 2. Client Run (Visual Cloud)
      glog.info('Running client-side Monte Carlo (${accountList.length} accounts)...');
      final clientResult = sim.run(
        accountList: accountList,
        incomeList: incomeList,
        outgoingList: outgoingList,
        transferList: transferList,
        dob: dob,
        volatility: volatility,
        rateAdjustment: rateAdjustment,
      );
      glog.info('Client-side simulation completed.');

      // 3. Merge
      // We keep server stats but overlay client monte paths
      result = SimulationResult(
        sumPotMin: serverResult.sumPotMin,
        sumPotMax: serverResult.sumPotMax, 
        incomeMin: serverResult.incomeMin,
        incomeMax: serverResult.incomeMax, 
        xAxisMin: serverResult.xAxisMin, 
        xAxisMax: serverResult.xAxisMax, 
        nameList: serverResult.nameList,
        sumList: serverResult.sumList, 
        incomeList: serverResult.incomeList, 
        accountMap: serverResult.accountMap, 
        monteMinList: serverResult.monteMinList, 
        monteMaxList: serverResult.monteMaxList, 
        ageList: serverResult.ageList,
        montePath: clientResult.montePath, // The cloud!
      );
      
      // Reset showList based on pots
      showList = List<bool>.filled(3 + result!.accountMap.length, true);
    } catch (e) {
      glog.severe('Simulation failed: $e');
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
    if (index >= 0 && index < showList.length) {
      showList[index] = !showList[index];
      notifyListeners();
    }
  }
}
