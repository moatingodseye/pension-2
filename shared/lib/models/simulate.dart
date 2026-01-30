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
  int id;
  double amount;
  Object source;
  bool use;

  Transaction(this.id, this.amount, this.source) : use=false;
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
  bool isInRange(DateTime earliest, int yearIndex, AgeOrDate startAt, AgeOrDate? endAt) {
    DateTime currentYearDate = addYear(earliest, yearIndex);
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

    if (s != null && currentYearDate.isBefore(s)) return false;
    if (e != null && currentYearDate.isAfter(e)) return false;

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
      t.use = isInRange(when, year, i.startAt, i.endAt);
    }

    for (Transaction t in outgoing) {
      Outgoing o = t.source as Outgoing;
      t.use = isInRange(when, year, o.startAt, o.endAt);
    }

    for (Transaction t in transfer) {
      Transfer r = t.source as Transfer;
      t.use = isInRange(when, year, r.startAt, r.endAt);
    }
  }

  SimulationResult? simulate(double volatility, double rateAdjustment, int stepMonth, int? endAge, int? durationYear) {
    if (accountList!.isEmpty) {
      return null;
    }

    // Earliest start date
    DateTime earliestDate = DateTime.now();
    if (accountList!.isNotEmpty) {
      AgeOrDate minDate = accountList!.first.amountAt;
      for (Account a in accountList!) {
        if (a.amountAt.date!.isBefore(minDate.date!)) minDate = a.amountAt;
      }
      earliestDate = minDate.date!;
    }

    prepare();

    final pensionList = accountList!.where((a) => a.type == AccountType.pension).toList();
    final current = accountList!.where((a) => a.type == AccountType.current).toList();

    // Determine End Date
    DateTime endDate;
    if (durationYear != null) {
        endDate = addYear(earliestDate, durationYear);
    } else if (endAge != null) {
        endDate = addYear(user.dob!, endAge);
    } else {
        endDate = addYear(user.dob!, maxAge); // Default 120
    }

    // Calculate total months and steps
    int totalMonth = (endDate.year - earliestDate.year) * 12 + (endDate.month - earliestDate.month);
    if (totalMonth < 1) totalMonth = 1;
    
    int count = (totalMonth / stepMonth).ceil();
    if (count < 1) count = 1;
    
    // Series Data
    Map<int, List<double>> accountSeries = {};
    for (Account a in accountList!) {
      if (a.id == null) continue;
      accountSeries[a.id!] = List.filled(count, 0.0);
      accountSeries[a.id!]![0] = a.amount;
    }

    Map<int,double> accountValue = {};
    List<double> sumValue = List.filled(count, 0);
    List<double> incomeValue = List.filled(count, 0); // Net Income (legacy)
    List<double> totalIncomeValue = List.filled(count, 0); // Total Money IN to Current
    List<double> totalOutgoingValue = List.filled(count, 0); // Total Money OUT of Current
    List<double> annualNetFlow = List.filled(count, 0); // Net Flow into Pension (Allocated to steps)
    
    List<double> ageValue = List.generate(count, (i) {
        DateTime stepDate = DateTime(earliestDate.year, earliestDate.month + (i * stepMonth));
        return yearsBetween(user.dob!, stepDate).toDouble();
    });

    // Initialise
    for (Account a in accountList!) {
      if (a.id == null) continue;
      accountValue[a.id!] = a.amount;
    }
    // Convert annual amounts to monthly for calculation
    for (Income i in incomeList!) {
      income.add(Transaction(i.id!,i.amount, i)); // Store monthly amount
    }
    for (Outgoing o in outgoingList!) {
      outgoing.add(Transaction(o.id!,o.amount, o)); // Store monthly amount
    }
    for (Transfer t in transferList!) {
      transfer.add(Transaction(t.id!,t.amount, t)); // Store monthly amount
    }

    // Simulation Loop
    for (int step = 0; step < count; step++) {
      if (step > 0) {
        // Apply rate to transactions (Compound annually)
        // Note: rate() compounds annual amount. We need to be careful with monthly steps.
        // Simplified: Apply rate growth every 12 months (or equivalent fraction)
        // For now, let's keep rate() logic but applied proportionally? 
        // Logic `rate()` multiplies amount by (1+rate).
        // If step is monthly, we shouldn't increase inflation every month!
        // FIXED: Only apply inflation once per year.
        
        DateTime currentStepDate = DateTime(earliestDate.year, earliestDate.month + (step * stepMonth));
        // Check if we passed a year boundary or simplified: just update rates annually
        // Simpler: Apply (1+rate)^(stepMonths/12) to transaction values? 
        // Existing logic was: `t.amount *= (1.0 + i.rate)`. This implies annual jump.
        // Let's stick to annual inflation update for now to avoid complexity explosion, 
        // checks if (step * stepMonths) % 12 == 0 roughly?
        // Better: Continuous inflation?
        // Let's stick to: Update transaction values annually.
        
        bool isYearBoundary = (step * stepMonth) % 12 < stepMonth; 
        if (isYearBoundary && step * stepMonth >= 12) {
             rate(); 
        }

        mark(earliestDate, (step * stepMonth / 12).floor()); // Mark active transactions based on year index
        
        // Trackers for this step
        double stepTotalIncome = 0;
        double stepTotalOutgoing = 0;
        double stepPensionNetFlow = 0;

        // Process each month in the step
        for (int m = 0; m < stepMonth; m++) {
           // Apply transactions
           
           // Incomes
           for (Transaction t in income) {
             if (t.use) {
               Income i = t.source as Income;
               if (accountValue.containsKey(i.intoId)) {
                 accountValue[i.intoId!] = (accountValue[i.intoId!] ?? 0) + t.amount;
                 if (current.isNotEmpty && i.intoId == current[0].id) {
                     stepTotalIncome += t.amount;
                 }
                 // Pension Flow?
                 // If income goes into pension, track it
                 if (pensionList.any((p) => p.id == i.intoId)) {
                     stepPensionNetFlow += t.amount;
                 }
               }
             }
           }
           
           // Outgoings
           for (Transaction t in outgoing) {
             if (t.use) {
               Outgoing o = t.source as Outgoing;
               if (accountValue.containsKey(o.fromId)) {
                 accountValue[o.fromId!] = (accountValue[o.fromId!] ?? 0) - t.amount;
                 if (current.isNotEmpty && o.fromId == current[0].id) {
                     stepTotalOutgoing += t.amount;
                 }
                 // Pension Flow?
                 if (pensionList.any((p) => p.id == o.fromId)) {
                     stepPensionNetFlow -= t.amount;
                 }
               }
             }
           }
           
           // Transfers
           for (Transaction t in transfer) {
             if (t.use) {
               Transfer r = t.source as Transfer;
               if (accountValue.containsKey(r.fromId) && accountValue.containsKey(r.intoId)) {
                  accountValue[r.fromId!] = (accountValue[r.fromId!] ?? 0) - t.amount;
                  accountValue[r.intoId!] = (accountValue[r.intoId!] ?? 0) + t.amount;
                  
                  // Track logic for Current Account Flow
                  if (current.isNotEmpty) {
                      if (r.intoId == current[0].id) stepTotalIncome += t.amount;
                      if (r.fromId == current[0].id) stepTotalOutgoing += t.amount;
                  }
                  
                  // Pension Flow
                  bool fromPension = pensionList.any((p) => p.id == r.fromId);
                  bool intoPension = pensionList.any((p) => p.id == r.intoId);
                  
                  if (intoPension && !fromPension) stepPensionNetFlow += t.amount;
                  if (fromPension && !intoPension) stepPensionNetFlow -= t.amount;
               }
             }
           }
        } // end month loop

        // Apply Interest (Compound for stepMonths)
        for (Account a in accountList!) {
           if (a.id == null) continue;
           int id = a.id!;
           double annualRate = a.rate + rateAdjustment;
           // monthly rate = (1+annual)^(1/12) - 1
           double monthlyRate = pow(1 + annualRate, 1.0/12.0) - 1.0;
           // step rate = (1+monthly)^(stepMonths) - 1
           double stepRate = pow(1 + monthlyRate, stepMonth) - 1.0;
           
           accountValue[id] = (accountValue[id] ?? 0.0) * (1.0 + stepRate);
           accountSeries[id]![step] = accountValue[id]!;
        }
        
        // Store Step Data
        if (current.isNotEmpty) {
            // Net Change (Legacy Income line)
            if (step > 0) {
               // Approximate "Net Income" as change in balance excluding interest? 
               // Or just (Income - Outgoing)?
               incomeValue[step] = stepTotalIncome - stepTotalOutgoing;
            }
        }
        
        totalIncomeValue[step] = stepTotalIncome;
        totalOutgoingValue[step] = stepTotalOutgoing;
        annualNetFlow[step] = stepPensionNetFlow;

        double total = 0;
        for (Account a in pensionList) {
          if (a.id != null) total += accountValue[a.id!]!;
        }
        sumValue[step] = total;
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
            double stepTimeYears = stepMonth / 12.0;
            double stepSigma = sigma * sqrt(stepTimeYears);
            double stepMu = (log(1 + annualRate) - 0.5 * sigma * sigma) * stepTimeYears;
            
            double shock = normal(rand);
            double growth = exp(stepMu + stepSigma * shock);
            
            bal = (bal + annualNetFlow[step]) * growth;
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
    double sumMin = sumValue.isNotEmpty ? sumValue.reduce(min) : 0;
    double sumMax = sumValue.isNotEmpty ? sumValue.reduce(max) : 100;
    double incMin = totalOutgoingValue.isNotEmpty ? totalOutgoingValue.reduce(min) : 0; // Use Outgoing as min (negative-ish visual?) or just 0
    double incMax = totalIncomeValue.isNotEmpty ? totalIncomeValue.reduce(max) : 100;
    double outMax = totalOutgoingValue.isNotEmpty ? totalOutgoingValue.reduce(max) : 100;
    if (outMax > incMax) incMax = outMax; // Scale for both

    if (pensionList.isNotEmpty) {
      double mcLow = mcMinList.isNotEmpty ? mcMinList.reduce(min) : 0;
      double mcHigh = mcMaxList.isNotEmpty ? mcMaxList.reduce(max) : 0;
      if (mcLow < sumMin) sumMin = mcLow;
      if (mcHigh > sumMax) sumMax = mcHigh;
    }

    return SimulationResult(
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
        ageList: ageValue,
        totalIncomeList: totalIncomeValue,
        totalOutgoingList: totalOutgoingValue,
        annualNetFlow: annualNetFlow
    );
  }
}
