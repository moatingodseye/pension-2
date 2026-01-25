import 'dart:math';
import 'debugLogger.dart';

import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/simulation_result.dart';
import 'package:shared/models/ageOrDate.dart';

class SimulationService {
  final List<Account> accountList;
  final List<Income> incomeList;
  final List<Outgoing> outgoingList;
  final List<Transfer> transferList;
  final DateTime dob;
  final double volatility;
  final double rateAdjustment;

  SimulationService({
    required this.accountList,
    required this.incomeList,
    required this.outgoingList,
    required this.transferList,
    required this.dob,
    this.volatility = 0.12,
    this.rateAdjustment = 0.0});

  // Box-Muller transform
  static double normal(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  // Local date helpers (replicating server properties)
  DateTime addYear(DateTime d, int years) {
    return DateTime(d.year + years, d.month, d.day);
  }

  // Years between dates (approx)
  double yearsBetween(DateTime from, DateTime to) {
    return (to.difference(from).inDays / 365.25);
  }

  // Helper: Check Range
  bool isInRange(
    DateTime dob,
    DateTime earliest,
    int yearIndex,
    AgeOrDate? startAt,
    AgeOrDate? endAt,
  ) {
    DateTime currentYearDate = addYear(earliest, yearIndex);
    DateTime? s;
    DateTime? e;

    if (startAt==null || (startAt.date==null && startAt.age==null)) return true;

    if (startAt.date != null) {
      s = startAt.date;
    }

    if (startAt.age != null) {
      //      int? age = int.tryParse(startAt);
      s = addYear(dob, startAt.age!);
    }

    // Parse End
    if (endAt==null || (endAt.date==null && endAt.age==null)) e = null;

    if (endAt?.date != null) {
      e = endAt?.date!;
    }
    if (endAt !=null && endAt.age != null) {
      e = addYear(dob,endAt.age!);
    }

    if (s != null && currentYearDate.isBefore(s)) return false;
    if (e != null && currentYearDate.isAfter(e)) return false;

    return true;
  }

  void prepare(DateTime dob) {
    // convert AgeOrDate's into dates to make comparison easier
    for (Account a in accountList) {
      if (a.id == null) continue;
      if (a.amountAt.age!=null)  {
        Account replace = Account.amountAt(a,amountAt:AgeOrDate(date:addYear(dob,a.amountAt.age!)));
        accountList[accountList.indexOf(a)] = replace;
      }
    }
  
    for (Income a in incomeList) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Income replace = Income.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        incomeList[incomeList.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Income replace = Income.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        incomeList[incomeList.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Outgoing a in outgoingList) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Outgoing replace = Outgoing.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        outgoingList[outgoingList.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Outgoing replace = Outgoing.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        outgoingList[outgoingList.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Transfer a in transferList) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Transfer replace = Transfer.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        transferList[transferList.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Transfer replace = Transfer.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        transferList[transferList.indexOf(a)] = replace;
        a = replace;
      }
    }
  }

  SimulationResult simulate() {
    // We can't access instance members in static method efficiently without passing logger?
    // 'log' from debugLogger is global.
    final stopwatch = Stopwatch()..start();

    // ---------------------------------------------------------
    // 1. SETUP & UTILS
    // ---------------------------------------------------------

    if (accountList.isEmpty) {
      stopwatch.stop();
      return SimulationResult(
        sumPotMin: 0,
        sumPotMax: 100,
        incomeMin: 0,
        incomeMax: 100,
        xAxisMin: 0,
        xAxisMax: 100,
        nameList: [],
        sumList: [],
        incomeList: [],
        accountMap: [],
        monteMinList: [],
        monteMaxList: [],
        ageList: [],
        montePath: [],
      );
    }

    const int maxAge = 77;//120;

    // Earliest start date
    DateTime earliestDate = DateTime.now();
    if (accountList.isNotEmpty) {
      AgeOrDate minDate = accountList.first.amountAt;
      for (Account a in accountList) {
        if (a.amountAt.date!.isBefore(minDate.date!)) minDate = a.amountAt;
      }
      earliestDate = minDate.date!;
    }

    // convert ages into dates for ease of comparison
    prepare(dob);

    DateTime endDate = addYear(dob, maxAge);
    int count = yearsBetween(earliestDate, endDate).toInt();
    if (count < 0) count = 0;

    // ---------------------------------------------------------
    // 2. DETERMINISTIC RUN (Base Case)
    // ---------------------------------------------------------

    // Map<AccountId, List<double>>
    Map<int, List<double>> accountSeries = {};

    for (Account a in accountList) {
      if (a.id == null) continue;
      accountSeries[a.id!] = List.filled(count, 0.0);
      accountSeries[a.id!]![0] = a.amount;
    }

    final current = accountList!.where((a) => a.type == AccountType.current).toList();
    final pensionList = accountList
        .where((a) => a.type == AccountType.pension)
        .toList();


    List<double> sumLine = List.filled(count, 0);
    List<double> incomeLine = List.filled(count, 0);
    List<double> ageList = List.generate(
      count,
      (i) => yearsBetween(dob, addYear(earliestDate, i)).toDouble(),
    );

    for (int y = 0; y < count; y++) {
      double currentTotal = current[0].amount;

      // Init year value (copy prev) & Interest
      for (Account a in accountList) {
        if (a.id == null) continue;
        int id = a.id!;

        if (y > 0) {
          accountSeries[id]![y] = accountSeries[id]![y - 1];
        }

        glog.info('');
        glog.info('Account:${a.id}/${a.name} year:$y initial value:${accountSeries[id]![y]}');

        // Incomes
        for (Income inc in incomeList) {
          if (isInRange(dob, earliestDate, y, inc.startAt, inc.endAt)) {
            double amount = inc.amount * 12; // needs rate applying and remembering from previous year.
            int? intoId = inc.intoId;
            if (id==intoId) {
              accountSeries[id]![y] += amount;
              glog.info('Account:${a.id}/${a.name} income $amount from ${inc.id}/${inc.name} now ${accountSeries[id]![y]}');
            }
          }
        }

        // Outgoings
        for (Outgoing out in outgoingList) {
          if (isInRange(dob, earliestDate, y, out.startAt, out.endAt)) {
            double amount = out.amount * 12; // rate again
            int? fromId = out.fromId;
            if (id==fromId) {
              accountSeries[id]![y] -= amount;
              if (accountSeries[id]![y] < 0) accountSeries[id]![y] = 0;
              glog.info('Account:${a.id}/${a.name} outgoing $amount into ${out.id}/${out.name} now ${accountSeries[id]![y]}');
            }
          }
        }

        // Transfers
        for (Transfer tr in transferList) {
          if (isInRange(dob, earliestDate, y, tr.startAt, tr.endAt)) {
            double amount = tr.amount * 12;
            int fromId = tr.fromId;
            int intoId = tr.intoId;

            if (id==fromId) {
//              double avail = accountSeries[fromId]![y];
//              double actual = (avail < amount) ? avail : amount;

              accountSeries[id]![y] -= amount;
              glog.info('Account:${a.id}/${a.name} transfer (out) $amount into $intoId now ${accountSeries[id]![y]}');
            }
            if (id==intoId) {
              accountSeries[id]![y] += amount;
              glog.info('Account:${a.id}/${a.name} transfer (in) $amount from $fromId now ${accountSeries[id]![y]}');
            }
          }
        }

        glog.info('Account:${a.id}/${a.name} value after transactions now ${accountSeries[id]![y]}');
        
        // Interest (Use rate adjustment)
        double rate = a.rate + rateAdjustment;
        accountSeries[id]![y] *= (1 + rate);

        glog.info('Account:${a.id}/${a.name} final after interest now ${accountSeries[id]![y]}');
      }
      incomeLine[y] = current[0].amount-currentTotal; // difference from start to end of year is how much income we had
      double total = 0;
      for (Account a in pensionList) {
        if (a.id != null && accountSeries.containsKey(a.id!)) {
          total += accountSeries[a.id!]![y];
        }
      }
      sumLine[y] = total;
    }

    // ---------------------------------------------------------
    // 3. MONTE CARLO SIMULATION
    // ---------------------------------------------------------

    int mcRuns = 3000;

    List<double> mcMinList = List.filled(count, 0.0);
    List<double> mcMaxList = List.filled(count, 0.0);
    List<List<double>> montePath = []; // Store all total-sum paths

    if (pensionList.isNotEmpty) {
      mcMinList = List.filled(count, double.infinity);
      mcMaxList = List.filled(count, double.negativeInfinity);

      // Prepare storage for paths
      montePath = List.generate(mcRuns, (_) => List.filled(count, 0.0));

      List<List<double>> mcResults = List.generate(
        mcRuns,
        (_) => List.filled(count, 0.0),
      );
      Random rand = Random();

      for (int run = 0; run < mcRuns; run++) {
        // Only Pension accounts are subject to volatility in this model logic
        Map<int, double> tempBalances = {
          for (Account p in pensionList) p.id!: p.amount,
        };

        for (int y = 0; y < count; y++) {
          double pensionTotal = 0;
          for (Account p in pensionList) {
            int id = p.id!;
            double bal = tempBalances[id]!;

            double baseRate = p.rate + rateAdjustment;
            double sigma = volatility;
            double shock = normal(rand);
            double mu = log(1 + baseRate) - 0.5 * sigma * sigma;
            bal *= exp(mu + sigma * shock);

            // Deduct Transfers Out (Simple Logic: Only check transfers explicitly FROM pension accounts)
            for (Transfer tr in transferList) {
              if (tr.fromId == id &&
                  isInRange(dob, earliestDate, y, tr.startAt, tr.endAt)) {
                double amt = tr.amount * 12;
                if (bal < amt) amt = bal;
                bal -= amt;
              }
            }
            if (bal < 0) bal = 0;
            tempBalances[id] = bal;
            pensionTotal += bal;
          }

          double nonPensionTotal = 0;
          // Get non-pension total from the deterministic run for this year
          for (Account a in accountList) {
            if (a.type != AccountType.pension && a.id != null) {
              nonPensionTotal += accountSeries[a.id!]![y];
            }
          }

          double totalWealth = pensionTotal + nonPensionTotal;
          mcResults[run][y] = totalWealth;
        }
      }

      montePath = mcResults;

      // Calc P25 and P75 for IQR
      for (int y = 0; y < count; y++) {
        List<double> yearValues = [];
        for (int r = 0; r < mcRuns; r++) {
          yearValues.add(mcResults[r][y]);
        }
        yearValues.sort();

        if (yearValues.isNotEmpty) {
          int p25Index = (mcRuns * 0.25).floor().clamp(0, mcRuns - 1);
          int p75Index = (mcRuns * 0.75).floor().clamp(0, mcRuns - 1);

          mcMinList[y] = yearValues[p25Index];
          mcMaxList[y] = yearValues[p75Index];
        }
      }
    }

    List<List<double>> accountMap = [];
    for (Account a in accountList) {
      if (a.id != null) accountMap.add(accountSeries[a.id!]!);
    }

    List<String> nameList = [];
    for (Account a in accountList) {
      if (a.id != null) nameList.add(a.name);
    }

    // Calc min max for axes
    double sumMin = sumLine.reduce(min);
    double sumMax = sumLine.reduce(max);
    double incMin = incomeLine.reduce(min);
    double incMax = incomeLine.reduce(max);
    if (pensionList.isNotEmpty) {
      double mcLow = mcMinList.reduce(min);
      double mcHigh = mcMaxList.reduce(max);
      if (mcLow < sumMin) sumMin = mcLow;
      if (mcHigh > sumMax) sumMax = mcHigh;
    }

    stopwatch.stop();
    glog.info('SimulationService: $count years simulated in ${stopwatch.elapsedMilliseconds}ms',);

    return SimulationResult(
      sumPotMin: sumMin,
      sumPotMax: sumMax,
      incomeMin: incMin,
      incomeMax: incMax,
      xAxisMin: ageList.isNotEmpty ? ageList.first : 0,
      xAxisMax: ageList.isNotEmpty ? ageList.last : 100,
      nameList: nameList,
      sumList: sumLine,
      incomeList: incomeLine,
      accountMap: accountMap,
      monteMinList: mcMinList,
      monteMaxList: mcMaxList,
      montePath: montePath, // Pass the full paths
      ageList: ageList,
    );
  }
}
