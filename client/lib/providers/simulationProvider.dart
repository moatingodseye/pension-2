import 'package:flutter/widgets.dart';
import 'package:shared/models.dart';
import 'package:shared/logic.dart';
import 'package:shared/models/simulation_result.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/user.dart';
import '../services/apiService.dart';
import '../services/simulation_service.dart';

class SimulationProvider with ChangeNotifier {
  Map<int, MonteCarloResult> _results = {};
  bool _isLoading = false;
  SimulationResult? _result;
  String? _error;
  Map<String, bool> _showList = {};

  Map<int, MonteCarloResult> get results => _results;
  bool get isLoading => _isLoading;
  SimulationResult? get result => _result;
  String? get error => _error;
  Map<String, bool> get showList => _showList;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await ApiService.getList('simulation/dashboard');
      
      _results = {};
      for (var item in list) {
        final accountId = item['accountId'] as int;
        final resultJson = item['result'] as Map<String, dynamic>;
        _results[accountId] = MonteCarloResult.fromJson(resultJson);
      }
    } catch (e) {
      print('Simulation load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> run({
    required double volatility,
    required double rateAdjustment,
    required bool byMonth,
    int? endAge,
    int? durationYear,
    required List<Account> accountList,
    required List<Income> incomeList,
    required List<Outgoing> outgoingList,
    required List<Transfer> transferList,
    required User user,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = SimulationService(
        accountList: accountList,
        incomeList: incomeList,
        outgoingList: outgoingList,
        transferList: transferList,
        user: user,
        volatility: volatility,
        rateAdjustment: rateAdjustment,
      );

      _result = service.simulate(
        byMonth: byMonth,
        endAge: endAge,
        durationYear: durationYear,
      );

      // Initialize showList for all accounts and special keys
      if (_result != null) {
        _showList = {
          'Sum': true,
          'Income': true,
          'Monte Carlo': true,
        };
        for (var name in _result!.nameList) {
          _showList[name] = true;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLine(String name) {
    _showList[name] = !(_showList[name] ?? false);
    notifyListeners();
  }

  MonteCarloResult? getResult(int accountId) => _results[accountId];
}
