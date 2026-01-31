import 'dart:math';
import 'debugLogger.dart';

import 'package:shared/models/user.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/simulation_result.dart';
import 'package:shared/models/ageOrDate.dart';
import 'package:shared/models/simulate.dart';

class SimulationService {
  final List<Account> accountList;
  final List<Income> incomeList;
  final List<Outgoing> outgoingList;
  final List<Transfer> transferList;
  final User user;
  final double volatility;
  final double rateAdjustment;

  SimulationService({
    required this.accountList,
    required this.incomeList,
    required this.outgoingList,
    required this.transferList,
    required this.user,
    this.volatility = 0.12,
    this.rateAdjustment = 0.0});

  SimulationResult? simulate({bool byMonth = false, int? endAge, int? durationYear}) {
    // We can't access instance members in static method efficiently without passing logger?
    // 'log' from debugLogger is global.
    final stopwatch = Stopwatch()..start();

    if (accountList.isEmpty) {
      stopwatch.stop();
      return null;
    }

    Simulate sim = Simulate(accountList, incomeList, outgoingList, transferList, user);
    SimulationResult? result = sim.simulate(volatility, rateAdjustment, byMonth, endAge, durationYear);

    stopwatch.stop();

    return result;
  }
}
