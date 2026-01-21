import 'dart:math';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';
import 'date.dart';
import 'debuglogger.dart'; // Import server logger

import 'package:shared/models/user.dart';
// ... checks ...

Future<Response> simulate(Request req) async {
  final db = pension.getDb();
  final uid = req.context['uid'];
  
  log.info('Simulate request received for user: $uid');

  final userRows = db.select("SELECT * FROM users WHERE id=?", [uid]);
  if (userRows.isEmpty) {
     log.warning('Simulate failed: User $uid not found');
     return Response.notFound('User not found');
  }
  
  // ...
  
  try {
    final bodyStr = await req.readAsString();
    if (bodyStr.isNotEmpty) {
      final body = jsonDecode(bodyStr);
      if (body is Map<String, dynamic>) {
        if (body.containsKey('volatility')) {
          volatility = (body['volatility'] as num).toDouble();
        }
        if (body.containsKey('rate_adjustment')) {
          rateAdjustment = (body['rate_adjustment'] as num).toDouble();
        }
      }
    }
    log.info('Simulation params: vol=$volatility, rateAdj=$rateAdjustment');
  } catch (e) {
    // Ignore body parsing errors, use defaults
    log.warning('Error parsing simulation params: $e');
  }

  // ... (Models mapping) ...
  final accounts = accRows.map((r) => Account.fromJson(r)).toList();
  final incomes = incRows.map((r) => Income.fromJson(r)).toList();
  final outgoings = outRows.map((r) => Outgoing.fromJson(r)).toList();
  final transfers = trRows.map((r) => Transfer.fromJson(r)).toList();

  if (accounts.isEmpty) {
     return Response.ok(jsonEncode(SimulationResult(
         sum: [], income: [], pots: [], monteMin: [], monteMax: [], ages: [],
         sumPotMin: 0, sumPotMax: 100, incomeMin: 0, incomeMax: 100, xAxisMin: 0, xAxisMax: 100
     ).toJson()), headers: {'Content-Type': 'application/json'});
  }

  const int maxYear = 120; // Age 120
  
  // Earliest start date
  DateTime earliestDate = DateTime.now();
  if (accounts.isNotEmpty) {
      DateTime minDate = accounts.first.amountAt;
      for (var a in accounts) {
          if (a.amountAt.isBefore(minDate)) minDate = a.amountAt;
      }
      earliestDate = minDate;
  }
  
  DateTime endDate = addYear(dob, maxYear);
  int count = yearsBetween(earliestDate, endDate).toInt(); 
  if (count < 0) count = 0;

  // Init series
  // Map<AccountId, List<double>>
  Map<int, List<double>> accountSeries = {};
  for (var a in accounts) {
    if (a.id == null) continue;
    accountSeries[a.id!] = List.filled(count, 0.0);
    accountSeries[a.id!]![0] = a.amount;
  }
  
  List<double> sumValues = List.filled(count, 0);
  List<double> incomeValues = List.filled(count, 0);
  List<double> ages = List.generate(count, (i) => yearsBetween(dob, addYear(earliestDate, i)).toDouble());

  // Helper: Check Range
  bool isInRange(int yearIndex, String startAt, String? endAt) {
    DateTime currentYearDate = addYear(earliestDate, yearIndex);
    DateTime? s;
    DateTime? e;
    
    // Parse Start
    if (startAt.contains('-')) {
        s = DateTime.tryParse(startAt);
    } else {
        int? age = int.tryParse(startAt);
        if (age != null) s = addYear(dob, age);
    }
    
    // Parse End
    if (endAt != null && endAt.isNotEmpty) {
        if (endAt.contains('-')) {
            e = DateTime.tryParse(endAt);
        } else {
            int? age = int.tryParse(endAt);
            if (age != null) e = addYear(dob, age);
        }
    }

    if (s != null && currentYearDate.isBefore(s)) return false;
    if (e != null && currentYearDate.isAfter(e)) return false;
    
    return true;
  }

  // Simulation Loop
  for (int y = 0; y < count; y++) {
      double yearIncomeTotal = 0;

      // Init year value (copy prev) & Interest
      for (var a in accounts) {
          if (a.id == null) continue;
          int id = a.id!;
          
          if (y > 0) {
              accountSeries[id]![y] = accountSeries[id]![y-1];
          }
          
          // Interest (Use rate adjustment)
          double rate = a.rate + rateAdjustment;
          accountSeries[id]![y] *= (1 + rate);
      }
      
      // Incomes
      for (var inc in incomes) {
          if (isInRange(y, inc.startAt, inc.endAt)) {
              double amount = inc.amount * 12; 
              int? intoId = inc.intoAccount;
              if (intoId != null && accountSeries.containsKey(intoId)) {
                  accountSeries[intoId]![y] += amount;
              }
              yearIncomeTotal += amount; 
          }
      }
      
      // Outgoings
      for (var out in outgoings) {
          if (isInRange(y, out.startAt, out.endAt)) {
              double amount = out.amount * 12;
              int? fromId = out.fromAccount;
              if (fromId != null && accountSeries.containsKey(fromId)) {
                  accountSeries[fromId]![y] -= amount;
                  if (accountSeries[fromId]![y] < 0) accountSeries[fromId]![y] = 0;
              }
          }
      }
      
      // Transfers
      for (var tr in transfers) {
          if (isInRange(y, tr.startAt, tr.endAt)) {
              double amount = tr.amount * 12;
              int fromId = tr.fromAccount;
              int intoId = tr.intoAccount;
              
              if (accountSeries.containsKey(fromId)) {
                  double avail = accountSeries[fromId]![y];
                  double actual = (avail < amount) ? avail : amount;
                  
                  accountSeries[fromId]![y] -= actual;
                  
                  if (accountSeries.containsKey(intoId)) {
                      accountSeries[intoId]![y] += actual;
                  }
              }
          }
      }
      
      incomeValues[y] = yearIncomeTotal;
      double total = 0;
      for(var a in accounts) {
          if (a.id != null) total += accountSeries[a.id!]![y];
      }
      sumValues[y] = total;
  }

  // MC
  int mcRuns = 2000;
  List<double> mcMin = List.filled(count, 0.0);
  List<double> mcMax = List.filled(count, 0.0);
  
  final pensionAccounts = accounts.where((a) => a.type == AccountType.pension).toList();
  
  if (pensionAccounts.isNotEmpty) {
      mcMin = List.filled(count, double.infinity);
      mcMax = List.filled(count, double.negativeInfinity);
      
      List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));
      Random rand = Random();
      
      for (int run = 0; run < mcRuns; run++) {
          Map<int, double> tempBalances = { for(var p in pensionAccounts) p.id! : p.amount };
          
          for(int y=0; y<count; y++) {
             double yearTotal = 0;
             for (var p in pensionAccounts) {
                 int id = p.id!;
                 double bal = tempBalances[id]!;
                 
                 double baseRate = p.rate + rateAdjustment; // Use adjusted rate
                 double sigma = volatility; // Use passed volatility
                 double shock = normal(rand);
                 double mu = log(1+baseRate) - 0.5*sigma*sigma;
                 bal *= exp(mu + sigma*shock);
                 
                 // Deduct Transfers Out
                 for(var tr in transfers) {
                     if (tr.fromAccount == id && isInRange(y, tr.startAt, tr.endAt)) {
                         double amt = tr.amount * 12;
                         if (bal < amt) amt = bal;
                         bal -= amt;
                     }
                 }
                 if(bal < 0) bal=0;
                 tempBalances[id] = bal;
                 yearTotal += bal;
             }
             mcResults[run][y] = yearTotal;
          }
      }
      
      for(int y=0; y<count; y++) {
          List<double> yearValues = [];
          for(int r=0; r<mcRuns; r++) {
              yearValues.add(mcResults[r][y]);
          }
          yearValues.sort();
          if (yearValues.isNotEmpty) {
             // 25th & 75th percentile
             int p25Index = (mcRuns * 0.25).floor().clamp(0, mcRuns - 1);
             int p75Index = (mcRuns * 0.75).floor().clamp(0, mcRuns - 1);
             
             mcMin[y] = yearValues[p25Index];
             mcMax[y] = yearValues[p75Index];
          }
      }
  }

  List<List<double>> potsList = [];
  for(var a in accounts) {
      if(a.id!=null) potsList.add(accountSeries[a.id!]!);
  }

  // Calc min max for axes
  double sumMin = sumValues.reduce(min);
  double sumMax = sumValues.reduce(max);
  double incMin = incomeValues.reduce(min);
  double incMax = incomeValues.reduce(max);
  if (pensionAccounts.isNotEmpty) {
      double mcLow = mcMin.reduce(min);
      double mcHigh = mcMax.reduce(max);
      if(mcLow < sumMin) sumMin = mcLow;
      if(mcHigh > sumMax) sumMax = mcHigh;
  }

  final result = SimulationResult(
      sumPotMin: sumMin,
      sumPotMax: sumMax,
      incomeMin: incMin,
      incomeMax: incMax,
      xAxisMin: ages.isNotEmpty ? ages.first : 0,
      xAxisMax: ages.isNotEmpty ? ages.last : 100,
      sum: sumValues,
      income: incomeValues,
      pots: potsList,
      monteMin: mcMin,
      monteMax: mcMax,
      ages: ages
  );

  return Response.ok(jsonEncode(result.toJson()), headers: {'Content-Type': 'application/json'});
}