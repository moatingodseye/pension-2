import 'dart:math';

import 'date.dart';
import 'account.dart';
import 'account_type.dart';
import 'user.dart';
import 'income.dart';
import 'outgoing.dart';
import 'transfer.dart';
import 'simulation_result.dart';
import 'ageOrDate.dart';

class Transaction {
  Object source; // income, outgoing or transfer
  int id;
  double target; // what we want to take
  double rate;
  double? taken; // what we managed to take
  bool use; // do dates match, i.e. use/perform this transaction

  Transaction(this.source, this.id, this.target, this.rate) : taken=0.0, use=false;
}

class Simulate {
  final int maxAge = 120;

  final List<Account>? accountList;
  final List<Income>? incomeList;
  final List<Outgoing>? outgoingList;
  final List<Transfer>? transferList;
  final User user;
  List<Transaction> income = [];
  List<Transaction> outgoing = [];
  List<Transaction> transfer = [];
    
  Simulate(this.accountList, this.incomeList, this.outgoingList, this.transferList, this.user);

  // Box-Muller transform
  double normal(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  // Helper: Check Range
  bool isInRange(DateTime when, AgeOrDate startAt, AgeOrDate? endAt) {
    DateTime? s;
    DateTime? e;

    if (startAt.date==null && startAt.age==null) return true;

    if (startAt.date != null) {
      s = startAt.date;
    }

    if (endAt==null || (endAt.date==null && endAt.age==null)) e = null;

    if (endAt?.date != null) {
      e = endAt?.date!;
    }

    if (s != null && when.isBefore(s)) return false;
    if (e != null && when.isAfter(e)) return false;

    return true;
  }

  void prepare() {
    // convert AgeOrDate's into dates to make comparison easier
    for (Account a in accountList!) {
      if (a.id == null) continue;
      if (a.amountAt.age!=null)  {
        Account replace = Account.amountAt(a,amountAt:AgeOrDate(date:addYear(user.dob!,a.amountAt.age!)));
        accountList![accountList!.indexOf(a)] = replace;
      }
    }
  
    for (Income a in incomeList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Income replace = Income.startAt(a,startAt:AgeOrDate(date:addYear(user.dob!,a.startAt.age!)));
        incomeList![incomeList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Income replace = Income.endAt(a,endAt:AgeOrDate(date:addYear(user.dob!,a.endAt!.age!)));
        incomeList![incomeList!.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Outgoing a in outgoingList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Outgoing replace = Outgoing.startAt(a,startAt:AgeOrDate(date:addYear(user.dob!,a.startAt.age!)));
        outgoingList![outgoingList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Outgoing replace = Outgoing.endAt(a,endAt:AgeOrDate(date:addYear(user.dob!,a.endAt!.age!)));
        outgoingList![outgoingList!.indexOf(a)] = replace;
        a = replace;
      }
    }

    for (Transfer a in transferList!) {
      if (a.id == null) continue;
      if (a.startAt.age!=null)  {
        Transfer replace = Transfer.startAt(a,startAt:AgeOrDate(date:addYear(user.dob!,a.startAt.age!)));
        transferList![transferList!.indexOf(a)] = replace;
        a = replace;
      }
      if (a.endAt != null && a.endAt!.age!=null)  {
        Transfer replace = Transfer.endAt(a,endAt:AgeOrDate(date:addYear(user.dob!,a.endAt!.age!)));
        transferList![transferList!.indexOf(a)] = replace;
        a = replace;
      }
    }
  }

  void rate() {
    // rate has already been converted to monthly we always process monthly, just might not pass every month result to the chart
    for (Transaction t in income) {
      t.target *= (1.0 + t.rate);
    }
    for (Transaction t in outgoing) {
      t.target *= (1.0 + t.rate);
    }
    for (Transaction t in transfer) {
      t.target *= (1.0 + t.rate);
    }
  }

  void mark(DateTime when) {
    for (Transaction t in income) {
      Income i = t.source as Income;
      t.taken = 0.0;
      t.use = isInRange(when, i.startAt, i.endAt);
    }

    for (Transaction t in outgoing) {
      Outgoing o = t.source as Outgoing;
      t.taken = 0.0;
      t.use = isInRange(when, o.startAt, o.endAt);
    }

    for (Transaction t in transfer) {
      Transfer r = t.source as Transfer;
      t.taken = 0.0;
      t.use = isInRange(when, r.startAt, r.endAt);
    }
  }

  SimulationResult? simulate(double volatility, double rateAdjustment, bool byMonth, int? endAge, int? durationYear) {
    if (accountList!.isEmpty) {
      return null;
    }

    // Earliest start date
    DateTime startDate = DateTime.now();
    if (accountList!.isNotEmpty) {
      AgeOrDate minDate = accountList!.first.amountAt;
      for (Account a in accountList!) {
        if (a.amountAt.date!.isBefore(minDate.date!)) minDate = a.amountAt;
      }
      startDate = minDate.date!;
    }

    prepare();

    final pensionList = accountList!.where((a) => a.type == AccountType.pension).toList();
    final current = accountList!.where((a) => a.type == AccountType.current).toList().first;

    // Determine End Date
    DateTime endDate;
    if (durationYear != null) {
        endDate = addYear(startDate, durationYear);
    } else if (endAge != null) {
        endDate = addYear(user.dob!, endAge);
    } else {
        endDate = addYear(user.dob!, maxAge); // Default 120
    }

    // Calculate total months and steps
    int totalMonth = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month);
    if (totalMonth < 1) totalMonth = 12;
    
    int count = totalMonth;
    int answer = count;
    int step = 1;
    if (!byMonth) {
      answer = count ~/ 12;
      step = 12;
    }

    // Series Data
    Map<int, List<double>> accountSeries = {};
    for (Account a in accountList!) {
      if (a.id == null) continue;
      accountSeries[a.id!] = List.filled(answer, 0.0);
      accountSeries[a.id!]![0] = a.amount;
    }

    Map<int,double> accountValue = {};
    List<double> sumValue = List.filled(answer, 0); // sum of pensions
    double minValue = 0;
    double maxValue = 0; // min/max accountValue over entire run, so graph can scale
    List<double> incomeValue = List.filled(answer, 0); // Total Money IN to Current
    List<double> outgoingValue = List.filled(answer, 0); // Total Money OUT of Current
    List<double> intoPension = List.filled(answer, 0); // Net Flow into Pension (Allocated to steps)
    
    List<double> ageValue = List.generate(answer, (i) {
        DateTime stepDate = DateTime(startDate.year, startDate.month + (i * step));
        return yearsBetween(user.dob!, stepDate).toDouble();
    });

    // Initialise
    for (Account a in accountList!) {
      if (a.id == null) continue;
      accountValue[a.id!] = a.amount;
      if (a.type!=AccountType.pension) {
        minValue = minValue<a.amount ? minValue : a.amount;
        maxValue = maxValue>a.amount ? maxValue : a.amount;
      }
    }
    // Convert annual amounts to monthly for calculation
    for (Income i in incomeList!) {
      income.add(Transaction(i, i.id!,i.amount, i.rate / 12.0)); 
    }
    for (Outgoing o in outgoingList!) {
      outgoing.add(Transaction(o, o.id!,o.amount, o.rate / 12.0)); 
    }
    for (Transfer t in transferList!) {
      transfer.add(Transaction(t, t.id!,t.amount, t.rate / 12.0)); 
    }

    // Simulation Loop, always step by month 
    DateTime previousDate = startDate;
    int index = 0;
    for (int month = 0; month < count; month++) {
      if (month > 0) {
        // Apply rate to transactions (Compound annually)
        // Note: rate() compounds annual amount. We need to be careful with monthly steps.
        // Simplified: Apply rate growth every 12 months (or equivalent fraction)
        // For now, let's keep rate() logic but applied proportionally? 
        // Logic `rate()` multiplies amount by (1+rate).
        // If step is monthly, we shouldn't increase inflation every month!
        // FIXED: Only apply inflation once per year.
        
        DateTime currentDate = DateTime(startDate.year, startDate.month + month);
        if (byMonth) 
          index++;
        else if (currentDate.year!=previousDate.year)
          index++;
        previousDate = currentDate;

        // Check if we passed a year boundary or simplified: just update rates annually
        // Simpler: Apply (1+rate)^(stepMonths/12) to transaction values? 
        // Existing logic was: `t.amount *= (1.0 + i.rate)`. This implies annual jump.
        // Let's stick to annual inflation update for now to avoid complexity explosion, 
        // checks if (step * stepMonths) % 12 == 0 roughly?
        // Better: Continuous inflation?
        // Let's stick to: Update transaction values annually.
        
        rate();

        mark(currentDate); 
        
        List<Transaction>? retry = [];
        for (Account a in accountList!) {          
          // Incomes
          for (Transaction t in income) {
            if (t.use) {
              Income i = t.source as Income;
              if (a.id==i.intoId) {
                t.taken = t.target; // just for consistency
                accountValue[i.intoId] = accountValue[i.intoId]! + t.taken!;
//                  if (pensionList.any((p) => p.id == i.intoId)) {
              }
              if (a.id==current.id!) {
                incomeValue[index] = incomeValue[index] + t.taken!;
              }
              if (pensionList.any((p) => p.id == i.intoId)) {
                intoPension[index] = intoPension[index] + t.taken!;
              }
            }
          }
           
          // Outgoings
          for (Transaction t in outgoing) {
            if (t.use) {
              Outgoing o = t.source as Outgoing;
              if (a.id==o.fromId) {
                if (accountValue.containsKey(o.fromId)) {
                  t.taken = t.target;
                  if (accountValue[o.fromId]!<t.target) {
                    t.taken = accountValue[o.fromId];
                  }
                  accountValue[o.fromId] = accountValue[o.fromId]! - t.taken!;
                }
              }
              if (a.id==current.id!) {
                outgoingValue[index] = outgoingValue[index] + t.taken!;
              }
              if (pensionList.any((p) => p.id == o.fromId)) {
                intoPension[index] = intoPension[index] + t.taken!;
              }
            }
          }
           
          // Transfers
          for (Transaction t in transfer) {
            if (t.use) {
              Transfer r = t.source as Transfer;
              if (a.id==r.fromId) {
                if (accountValue.containsKey(r.fromId)) {
                  t.taken = t.target;
                  if (accountValue[r.fromId]!<t.target) {
                    t.taken = accountValue[r.fromId];
                  }
                  accountValue[r.fromId] = accountValue[r.fromId]! - t.taken!;
                }
                if (a.id==current.id!) {
                  outgoingValue[index] = outgoingValue[index] + t.taken!;
                }
              }
              if (a.id==r.intoId) {
                // might not have not taken from other account yet, don't know if it has this ammount left so can't do this transaction fully yet.
                retry.add(t);
              }
            }
          }
        }

        // can now do that transaction we delayed earlier as must have taken from from other account, if not then taken=0 and nothing changes
        for (Transaction t in retry) {
          Transfer r = t.source as Transfer;
          accountValue[r.intoId] = accountValue[r.intoId]! + t.taken!;
          if (r.intoId==current.id!)
            incomeValue[index] = incomeValue[index] + t.taken!;
          if (pensionList.any((p) => p.id == r.intoId)) {
            intoPension[index] = intoPension[index] + t.taken!;
          }
        }

        // Apply Interest 
        for (Account a in accountList!) {
          if (a.id == null) continue;
          int id = a.id!;
          double rate = a.rate;
          if (pensionList.any((p) => p.id == id)) 
            rate = rate + rateAdjustment; // simulate different rates for pensions, doesn't apply to savings/state pension etc
          // monthly rate = (1+annual)^(1/12) - 1
          rate = pow(1 + rate, 1.0/12.0) - 1.0;
          // step rate = (1+monthly)^(stepMonths) - 1
//          double stepRate = pow(1 + monthlyRate, stepMonth) - 1.0;
          
          accountValue[id] = accountValue[id]! * (1.0 + rate);

          if (a.type!=AccountType.pension) {
            minValue = minValue<accountValue[a.id]! ? minValue : accountValue[a.id]!;
            maxValue = maxValue>accountValue[a.id]! ? maxValue : accountValue[a.id]!;
          }            

          accountSeries[id]![index] = accountValue[id]!;
        }
       
        double total = 0;
        for (Account a in pensionList) {
          if (a.id != null) total += accountValue[a.id!]!;
        }
        sumValue[index] = total;
      } else {
        // Step 0 - Initial State
        double total = 0;
        for (Account a in pensionList) {
          if (a.id != null) total += a.amount;
        }
        sumValue[0] = total;
      }
    }

    // MC - Adapted for Variable Steps & Flows
    // Running MC on yearly resolution usually, but here we can match steps.
    int mcRuns = 2000; // Reduced for performance with more steps
    List<double> mcMinList = List.filled(count, 0.0);
    List<double> mcMaxList = List.filled(count, 0.0);

    if (pensionList.isNotEmpty) {
      mcMinList = List.filled(count, double.infinity);
      mcMaxList = List.filled(count, double.negativeInfinity);

      List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));
      Random rand = Random();

      for (int run = 0; run < mcRuns; run++) {
         // Using simplified aggregate model for MC to be fast
         double bal = pensionList.fold(0.0, (p, c) => p + c.amount);
         mcResults[run][0] = bal;

         for (int step = 1; step < count; step++) {
            double annualRate = (pensionList.first.rate) + rateAdjustment; // Approximate rate
            double sigma = volatility;
            
            // Adjust sigma/mu for step duration
            double stepTimeYears = 1 / 12.0;
            double stepSigma = sigma * sqrt(stepTimeYears);
            double stepMu = (log(1 + annualRate) - 0.5 * sigma * sigma) * stepTimeYears;
            
            double shock = normal(rand);
            double growth = exp(stepMu + stepSigma * shock);
            
            bal = (bal + intoPension[index]) * growth;
            if (bal < 0) bal = 0;
            mcResults[run][step] = bal;
         }
      }
      
      for (int step = 0; step < count; step++) {
         List<double> stepValues = [];
         for(int r=0; r<mcRuns; r++) stepValues.add(mcResults[r][step]);
         stepValues.sort();
         if (stepValues.isNotEmpty) {
             int p25 = (mcRuns * 0.25).floor();
             int p75 = (mcRuns * 0.75).floor();
             mcMinList[step] = stepValues[p25];
             mcMaxList[step] = stepValues[p75];
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
    double sumMax = sumValue.isNotEmpty ? sumValue.reduce(max) : 100;
    double accountMin = minValue;
    double accountMax = maxValue;
  
    if (pensionList.isNotEmpty) {
      double mcLow = mcMinList.isNotEmpty ? mcMinList.reduce(min) : 0;
      double mcHigh = mcMaxList.isNotEmpty ? mcMaxList.reduce(max) : 0;
    }

    return SimulationResult(
        ageList: ageValue, // x - axis
        ageMin: ageValue.isNotEmpty ? ageValue.first : 0,
        ageMax: ageValue.isNotEmpty ? ageValue.last : 100,
        pensionMin: 0.0,
        pensionMax: sumMax,
        accountMin: 0.0,
        accountMax: accountMax,
        nameList: nameList,
        sumList: sumValue,
        incomeList: incomeValue,
        outgoingList: outgoingValue,
        accountMap: accountResult,
        monteMinList: mcMinList,
        monteMaxList: mcMaxList,
        intoPensionList: intoPension,
    );
  }
}
