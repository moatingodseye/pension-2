import 'dart:math';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'db.dart';
import 'date.dart';
import 'debuglogger.dart'; // Import server logger
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/user.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/simulation_result.dart';

// Box-Muller transform
double normal(Random rand) {
  final u1 = rand.nextDouble();
  final u2 = rand.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}

// Helper: Check Range
bool isInRange(User user, DateTime earliest, int yearIndex, String startAt,
    String? endAt) {
  DateTime currentYearDate = addYear(earliest, yearIndex);
  DateTime? s;
  DateTime? e;

// Parse Start
  if (startAt.contains('-')) {
    s = DateTime.tryParse(startAt);
  } else {
    int? age = int.tryParse(startAt);
    if (age != null) s = addYear(user.dob!, age);
  }

// Parse End
  if (endAt != null && endAt.isNotEmpty) {
    if (endAt.contains('-')) {
      e = DateTime.tryParse(endAt);
    } else {
      int? age = int.tryParse(endAt);
      if (age != null) e = addYear(user.dob!, age);
    }
  }

  if (s != null && currentYearDate.isBefore(s)) return false;
  if (e != null && currentYearDate.isAfter(e)) return false;

  return true;
}

Future<Response> simulate(Request req) async {
  final db = pension.getDb();
  final uid = req.context['uid'];

  glog.info('Simulate request received for user: $uid');

  final userRow = db.select("SELECT * FROM user WHERE id=?", [uid]);
  if (userRow.isEmpty) {
    glog.warning('Simulate failed: User $uid not found');
    return Response.notFound('User not found');
  }

  final User user = User.fromJson(userRow.first);
  final accRow = db.select("SELECT * FROM account WHERE userId=?", [uid]);
  final incRow = db.select("SELECT * FROM income WHERE userId=?", [uid]);
  final outRow = db.select("SELECT * FROM outgoing WHERE userId=?", [uid]);
  final traRow = db.select("SELECT * FROM transfer WHERE userId=?", [uid]);
  // ...

  final bodyStr = await req.readAsString();

  final decoded = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : null;

  final Map<String, dynamic>? body =
      decoded is Map<String, dynamic> ? decoded : null;

  final double volatility =
      body != null ? (body['volatility'] as num?)?.toDouble() ?? 1.0 : 1.0;

  final double rateAdjustment =
      body != null ? (body['rate_adjustment'] as num?)?.toDouble() ?? 1.0 : 1.0;

  glog.info('Simulation params: vol=$volatility, rateAdj=$rateAdjustment');

  // ... (Models mapping) ...
  final account = accRow.map((r) => Account.fromJson(r)).toList();
  final income = incRow.map((r) => Income.fromJson(r)).toList();
  final outgoing = outRow.map((r) => Outgoing.fromJson(r)).toList();
  final transfer = traRow.map((r) => Transfer.fromJson(r)).toList();

  if (account.isEmpty) {
    return Response.ok(
        jsonEncode(SimulationResult(
                nameList: [],
                sumList: [],
                incomeList: [],
                accountMap: [],
                monteMinList: [],
                monteMaxList: [],
                ageList: [],
                sumPotMin: 0,
                sumPotMax: 100,
                incomeMin: 0,
                incomeMax: 100,
                xAxisMin: 0,
                xAxisMax: 100)
            .toJson()),
        headers: {'Content-Type': 'application/json'});
  }

  const int maxAge = 120;

  // Earliest start date
  DateTime earliestDate = DateTime.now();
  if (account.isNotEmpty) {
    DateTime minDate = account.first.amountAt;
    for (Account a in account) {
      if (a.amountAt.isBefore(minDate)) minDate = a.amountAt;
    }
    earliestDate = minDate;
  }

  DateTime endDate = addYear(user.dob!, maxAge);
  int count = yearsBetween(earliestDate, endDate).toInt();
  if (count < 0) count = 1;

  // Init series
  // Map<AccountId, List<double>>
  Map<int, List<double>> accountSeries = {};
  for (Account a in account) {
    if (a.id == null) continue;
    accountSeries[a.id!] = List.filled(count, 0.0);
    accountSeries[a.id!]![0] = a.amount;
  }

  List<double> sumList = List.filled(count, 0);
  List<double> incomeList = List.filled(count, 0);
  List<double> ageList = List.generate(count,
      (i) => yearsBetween(user.dob!, addYear(earliestDate, i)).toDouble());

  // Simulation Loop
  for (int y = 0; y < count; y++) {
    double yearIncomeTotal = 0;

    // Init year value (copy prev) & Interest
    for (Account a in account) {
      if (a.id == null) continue;
      int id = a.id!;

      if (y > 0) {
        accountSeries[id]![y] = accountSeries[id]![y - 1];
      }

      // Incomes
      for (Income inc in income) {
        if (isInRange(user, earliestDate, y, inc.startAt, inc.endAt)) {
          double amount = inc.amount * 12;
          int? intoId = inc.intoAccount;
          if (id==intoId) {
            accountSeries[id]![y] += amount;
          }
          yearIncomeTotal += amount;
        }
      }

      // Outgoings
      for (Outgoing out in outgoing) {
        if (isInRange(user, earliestDate, y, out.startAt, out.endAt)) {
          double amount = out.amount * 12;
          int? fromId = out.fromAccount;
          if (id==fromId) {
            accountSeries[id]![y] -= amount;
            if (accountSeries[id]![y] < 0) accountSeries[id]![y] = 0;
          }
        }
      }

      // Transfers
      for (Transfer tr in transfer) {
        if (isInRange(user, earliestDate, y, tr.startAt, tr.endAt)) {
          double amount = tr.amount * 12;
          int fromId = tr.fromAccount;
          int intoId = tr.intoAccount;

          if (id==(fromId)) {
//            double avail = accountSeries[id]![y];
//            double actual = (avail < amount) ? avail : amount;

            accountSeries[id]![y] -= amount;
          }
          if (id==(intoId)) {
              accountSeries[id]![y] += amount;
          }
        }
      }

      // Interest (Use rate adjustment)
      double rate = a.rate + rateAdjustment;
      accountSeries[id]![y] *= (1 + rate);
    }

    incomeList[y] = yearIncomeTotal;
    double total = 0;
    for (Account a in account) {
      if (a.id != null) total += accountSeries[a.id!]![y];
    }
    sumList[y] = total;
  }

  // MC
  int mcRuns = 2000;
  List<double> mcMinList = List.filled(count, 0.0);
  List<double> mcMaxList = List.filled(count, 0.0);

  final pensionAccount = account.where((a) => a.type == AccountType.pension).toList();

  if (pensionAccount.isNotEmpty) {
    mcMinList = List.filled(count, double.infinity);
    mcMaxList = List.filled(count, double.negativeInfinity);

    List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));
    Random rand = Random();

    for (int run = 0; run < mcRuns; run++) {
      Map<int, double> tempBalances = {
        for (Account p in pensionAccount) p.id!: p.amount
      };

      for (int y = 0; y < count; y++) {
        double yearTotal = 0;
        for (Account p in pensionAccount) {
          int id = p.id!;
          double bal = tempBalances[id]!;

          double baseRate = p.rate + rateAdjustment; // Use adjusted rate
          double sigma = volatility; // Use passed volatility
          double shock = normal(rand);
          double mu = log(1 + baseRate) - 0.5 * sigma * sigma;
          bal *= exp(mu + sigma * shock);

          // Deduct Transfers Out
          for (Transfer tr in transfer) {
            if (tr.fromAccount == id &&
                isInRange(user, earliestDate, y, tr.startAt, tr.endAt)) {
              double amt = tr.amount * 12;
              if (bal < amt) amt = bal;
              bal -= amt;
            }
          }
          if (bal < 0) bal = 0;
          tempBalances[id] = bal;
          yearTotal += bal;
        }
        mcResults[run][y] = yearTotal;
      }
    }

    for (int y = 0; y < count; y++) {
      List<double> yearValues = [];
      for (int r = 0; r < mcRuns; r++) {
        yearValues.add(mcResults[r][y]);
      }
      yearValues.sort();
      if (yearValues.isNotEmpty) {
        // 25th & 75th percentile
        int p25Index = (mcRuns * 0.25).floor().clamp(0, mcRuns - 1);
        int p75Index = (mcRuns * 0.75).floor().clamp(0, mcRuns - 1);

        mcMinList[y] = yearValues[p25Index];
        mcMaxList[y] = yearValues[p75Index];
      }
    }
  }

  List<List<double>> accountList = [];
  for (Account a in account) {
    if (a.id != null) accountList.add(accountSeries[a.id!]!);
  }

  List<String> nameList = [];
  for (Account a in account) {
    if (a.id != null) nameList.add(a.name);
  }

  // Calc min max for axes
  double sumMin = sumList.reduce(min);
  double sumMax = sumList.reduce(max);
  double incMin = incomeList.reduce(min);
  double incMax = incomeList.reduce(max);
  if (pensionAccount.isNotEmpty) {
    double mcLow = mcMinList.reduce(min);
    double mcHigh = mcMaxList.reduce(max);
    if (mcLow < sumMin) sumMin = mcLow;
    if (mcHigh > sumMax) sumMax = mcHigh;
  }

  final result = SimulationResult(
      sumPotMin: sumMin,
      sumPotMax: sumMax,
      incomeMin: incMin,
      incomeMax: incMax,
      xAxisMin: ageList.isNotEmpty ? ageList.first : 0,
      xAxisMax: ageList.isNotEmpty ? ageList.last : 100,
      nameList: nameList,
      sumList: sumList,
      incomeList: incomeList,
      accountMap: accountList,
      monteMinList: mcMinList,
      monteMaxList: mcMaxList,
      ageList: ageList);

  return Response.ok(jsonEncode(result.toJson()),
      headers: {'Content-Type': 'application/json'});
}
