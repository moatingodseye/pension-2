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
import 'package:shared/models/ageOrDate.dart';

class Transaction {
  int id;
  double amount;
  Object source;
  bool use;

  Transaction(this.id, this.amount, this.source) : use=false;
}

class Simulate {
  List<Account>? accountList;
  List<Income>? incomeList;
  List<Outgoing>? outgoingList;
  List<Transfer>? transferList;
  User? user;
  List<Transaction> income = [];
  List<Transaction> outgoing = [];
  List<Transaction> transfer = [];
    
  // Box-Muller transform
  double normal(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  // Helper: Check Range
  bool isInRange(User user, DateTime earliest, int yearIndex, AgeOrDate startAt, AgeOrDate? endAt) {
    DateTime currentYearDate = addYear(earliest, yearIndex);
    DateTime? s;
    DateTime? e;

    if (startAt.date==null && startAt.age==null) return true;

    if (startAt.date != null) {
      s = startAt.date;
    }

    if (startAt.age != null) {
      //      int? age = int.tryParse(startAt);
      s = addYear(user.dob!, startAt.age!);
    }

    // Parse End
    if (endAt==null || (endAt.date==null && endAt.age==null)) e = null;

    if (endAt?.date != null) {
      e = endAt?.date!;
    }
    if (endAt !=null && endAt.age != null) {
      e = addYear(user.dob!,endAt.age!);
    }

    if (s != null && currentYearDate.isBefore(s)) return false;
    if (e != null && currentYearDate.isAfter(e)) return false;

//    glog.info('inRange $currentYearDate $s $e gives $result');
    return true;
  }

  void prepare(DateTime dob) {
    // convert AgeOrDate's into dates to make comparison easier
    for (Account a in accountList!) {
      if (a.id == null) continue;
      if (a.amountAt.age!=null)  {
        Account replace = Account.amountAt(a,amountAt:AgeOrDate(date:addYear(dob,a.amountAt.age!)));
        accountList![accountList!.indexOf(a)] = replace;
      }
    }
  
    for (Income a in incomeList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Income replace = Income.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        incomeList![incomeList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Income replace = Income.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        incomeList![incomeList!.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Outgoing a in outgoingList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Outgoing replace = Outgoing.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        outgoingList![outgoingList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Outgoing replace = Outgoing.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        outgoingList![outgoingList!.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Transfer a in transferList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Transfer replace = Transfer.startAt(a,startAt:AgeOrDate(date:addYear(dob,a.startAt.age!)));
        transferList![transferList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Transfer replace = Transfer.endAt(a,endAt:AgeOrDate(date:addYear(dob,a.endAt!.age!)));
        transferList![transferList!.indexOf(a)] = replace;
        a = replace;
      }
    }
  }

  void rate() {
    for (Transaction t in income) {
      Income i = t.source as Income;
      t.amount *= (1.0 + i.rate);
    }
    for (Transaction t in outgoing) {
      Outgoing o = t.source as Outgoing;
      t.amount *= (1.0 + o.rate);
    }
    for (Transaction t in transfer) {
      Transfer r = t.source as Transfer;
      t.amount *= (1.0 + r.rate);
    }
  }

  void mark(DateTime when, int year) {
    for (Transaction t in income) {
      Income i = t.source as Income;
      t.use = isInRange(user!, when, year, i.startAt, i.endAt);
    }

    for (Transaction t in outgoing) {
      Outgoing o = t.source as Outgoing;
      t.use = isInRange(user!, when, year, o.startAt, o.endAt);
    }

    for (Transaction t in transfer) {
      Transfer r = t.source as Transfer;
      t.use = isInRange(user!, when, year, r.startAt, r.endAt);
    }
  }

  bool load(int uid) {
    final db = pension.getDb();

    glog.info('Simulate request received for user: $uid');

    final userRow = db.select("SELECT * FROM user WHERE id=?", [uid]);
    if (userRow.isEmpty) {
      glog.warning('Simulate failed: User $uid not found');
      return false;
    }

    user = User.fromDb(userRow.first);
    final accRow = db.select("SELECT * FROM account WHERE userId=?", [uid]);
    final incRow = db.select("SELECT * FROM income WHERE userId=?", [uid]);
    final outRow = db.select("SELECT * FROM outgoing WHERE userId=?", [uid]);
    final traRow = db.select("SELECT * FROM transfer WHERE userId=?", [uid]);

    // ... (Models mapping) ...
    accountList = accRow.map((r) => Account.fromDb(r)).toList();
    incomeList = incRow.map((r) => Income.fromDb(r)).toList();
    outgoingList = outRow.map((r) => Outgoing.fromDb(r)).toList();
    transferList = traRow.map((r) => Transfer.fromDb(r)).toList();

    return true;
  }

  Future<Response> simulate(Request req) async {
    final uid = req.context['uid'] as int;
    glog.info('Simulate request received for user: $uid');

    if (!load(uid)) {
      glog.warning('Simulate failed: User $uid not found');
      return Response.notFound('User not found');
    } else {

      final bodyStr = await req.readAsString();
      final decoded = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : null;
      final Map<String, dynamic>? body =
          decoded is Map<String, dynamic> ? decoded : null;
      final double volatility =
          body != null ? (body['volatility'] as num?)?.toDouble() ?? 1.0 : 1.0;
      final double rateAdjustment =
          body != null ? (body['rate_adjustment'] as num?)?.toDouble() ?? 1.0 : 1.0;

      glog.info('Simulation params: vol=$volatility, rateAdj=$rateAdjustment');

      if (accountList!.isEmpty) {
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
      if (accountList!.isNotEmpty) {
        AgeOrDate minDate = accountList!.first.amountAt;
        for (Account a in accountList!) {
          if (a.amountAt.date!.isBefore(minDate.date!)) minDate = a.amountAt;
        }
        earliestDate = minDate.date!;
      }

      prepare(user!.dob!);

      final pensionList = accountList!.where((a) => a.type == AccountType.pension).toList();
      final current = accountList!.where((a) => a.type == AccountType.current).toList();

      DateTime endDate = addYear(user!.dob!, maxAge);
      int count = yearsBetween(earliestDate, endDate).toInt();
      if (count < 0) count = 1;

      Map<int, List<double>> accountSeries = {};
      for (Account a in accountList!) {
        if (a.id == null) continue;
        accountSeries[a.id!] = List.filled(count, 0.0);
        accountSeries[a.id!]![0] = a.amount;
      }

      Map<int,double> accountValue = {};
      List<double> sumValue = List.filled(count, 0);
      List<double> incomeValue = List.filled(count, 0);
      List<double> ageValue = List.generate(count,
          (i) => yearsBetween(user!.dob!, addYear(earliestDate, i)).toDouble());

      // Initialise
      for (Account a in accountList!) {
        if (a.id == null) continue;
        accountValue[a.id!] = a.amount;
      }
      for (Income i in incomeList!) {
        income.add(Transaction(i.id!,i.amount * 12,i));
      }
      for (Outgoing o in outgoingList!) {
        outgoing.add(Transaction(o.id!,o.amount * 12,o));
      }
      for (Transfer t in transferList!) {
        transfer.add(Transaction(t.id!,t.amount * 12,t));
      }

      int x = 0;

      // Simulation Loop
      for (int y = 0; y < count; y++) {

        if (y>0) { // stgart at year 1, so 0=unaffected 1=after 1 year
          rate(); // apply rate to all transactions
          mark(earliestDate,y); // mark which transactions apply to this year
          double currentTotal = accountValue[current[0].id]!;

          // Init year value (copy prev) & Interest
          for (Account a in accountList!) {
            if (a.id == null) continue;
            int id = a.id!;

            if (id==2) {
              x = 1;
            }

            accountSeries[id]![y] = accountSeries[id]![y - 1];

            // Incomes
            for (Transaction t in income) {
              if (t.use) {
                Income i = t.source as Income;
                if (id==i.intoId) {
                  accountSeries[id]![y] += t.amount;
                  accountValue[id] = (accountValue[id] ?? 0) + t.amount;
                }
              }
            }

            // Outgoings
            for (Transaction t in outgoing) {
              if (t.use) {
                Outgoing o = t.source as Outgoing;
                if (id==o.fromId) {
                  accountSeries[id]![y] -= t.amount;
                  accountValue[id] = (accountValue[id] ?? 0) - t.amount;
                  if (accountSeries[id]![y] < 0) accountSeries[id]![y] = 0;
                }
              }
            }

            // Transfers
            for (Transaction t in transfer) {
              if (t.use) {
                Transfer r = t.source as Transfer;
                if (id==r.fromId || id==r.intoId) {
                  if (id==r.fromId) {
                    accountSeries[id]![y] -= t.amount;
                    accountValue[id] = (accountValue[id] ?? 0.0) - t.amount;
                  }
                  if (id==r.intoId) {
                    accountSeries[id]![y] += t.amount;
                    accountValue[id] = (accountValue[id] ?? 0.0) + t.amount;
                  }
                }
              }
            }

            // Interest (Use rate adjustment)
            double rate = a.rate + rateAdjustment;
            accountSeries[id]![y] *= (1 + rate);
            accountValue[id] = (accountValue[id] ?? 0.0) * (1.0 + rate);
          }
          
          incomeValue[y] = accountValue[current[0].id]!-currentTotal;
          double total = 0;
          for (Account a in pensionList) {
            if (a.id != null) total += accountSeries[a.id!]![y];
          }
          sumValue[y] = total;
        }
      }

      // MC
      int mcRuns = 10000;
      List<double> mcMinList = List.filled(count, 0.0);
      List<double> mcMaxList = List.filled(count, 0.0);

      if (pensionList.isNotEmpty) {
        mcMinList = List.filled(count, double.infinity);
        mcMaxList = List.filled(count, double.negativeInfinity);

        List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));
        Random rand = Random();

        for (int run = 0; run < mcRuns; run++) {
          Map<int, double> tempBalances = {
            for (Account p in pensionList) p.id!: p.amount
          };

          for (int y = 0; y < count; y++) {
            double yearTotal = 0;
            for (Account p in pensionList) {
              int id = p.id!;
              double bal = tempBalances[id]!;

              double baseRate = p.rate + rateAdjustment; // Use adjusted rate
              double sigma = volatility; // Use passed volatility
              double shock = normal(rand);
              double mu = log(1 + baseRate) - 0.5 * sigma * sigma;
              bal *= exp(mu + sigma * shock);

              // Deduct Transfers Out
              for (Transfer tr in transferList!) {
                if (tr.fromId == id &&
                    isInRange(user!, earliestDate, y, tr.startAt, tr.endAt)) {
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

      List<List<double>> accountResult = [];
      for (Account a in accountList!) {
        if (a.id != null) accountResult.add(accountSeries[a.id!]!);
      }

      List<String> nameList = [];
      for (Account a in accountList!) {
        if (a.id != null) nameList.add(a.name);
      }

      // Calc min max for axes
      double sumMin = sumValue.reduce(min);
      double sumMax = sumValue.reduce(max);
      double incMin = incomeValue.reduce(min);
      double incMax = incomeValue.reduce(max);
      if (pensionList.isNotEmpty) {
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
          xAxisMin: ageValue.isNotEmpty ? ageValue.first : 0,
          xAxisMax: ageValue.isNotEmpty ? ageValue.last : 100,
          nameList: nameList,
          sumList: sumValue,
          incomeList: incomeValue,
          accountMap: accountResult,
          monteMinList: mcMinList,
          monteMaxList: mcMaxList,
          ageList: ageValue);

      return Response.ok(jsonEncode(result.toJson()),
          headers: {'Content-Type': 'application/json'});
    }
  }
}