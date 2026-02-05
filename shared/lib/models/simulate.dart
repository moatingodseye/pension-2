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

// the processing information for the simulation
class Simulation {
  final Simulate parent;
  final bool byMonth;
  final DateTime start;
  final DateTime end;
  final int monthCount; // number of months to process (end-start)
  final int sampleCount; // number of samples to take (if by year the<>monthCount)
  final int step; // if by year = 1 if by month = 12, number of steps in process to take before doing a sample
  DateTime current;
  DateTime previous;
  int month = 0;
  int sample = 0;

  Simulation(this.parent, this.byMonth, this.start, this.end, this.monthCount, this.sampleCount, this.step) 
    : current = start, previous=start;

  void toWork(Map<int,Working> working) {
//    DateTime next = DateTime(current.year,current.month+1);
    for (final work in working.values) {
      Account a = work.source;
      if ((a.amountAt.date!.isAfter(current) || a.amountAt.date!.isAtSameMomentAs(current))) {
        // only reset amount if it wasn't being used otherwise lose changes over time.
        if (!work.use)
          work.amount = a.amount;
        work.use = true;
//      } else {
//        if (work.use)
//          work.amount = 0.0;
//        work.use = false;
      }
    }
  }

  void begin(Map<int,Working> working) {
    month = 0;
    sample = 0;
    current = start;
    previous = start;

    toWork(working);
  }

  void next(Map<int,Working> working) {
    month++;
    current = DateTime(start.year, start.month + month);
    if (byMonth) 
      sample++;
    else if (current.year!=previous.year) 
      sample++;
    previous = current;

    toWork(working);
  }
}

// during processing this is the Working representation of an account, has current value and maximum
class Working {
  final Account source;
  double _amount;
  double maximum;
  bool use;

  Working(this.source) : _amount = 0, maximum = 0, use = false;

  double get amount => _amount;
  void set amount(double value) {
    _amount = value;
    if (maximum<_amount)
      maximum = _amount;
  }
}

class Transaction {
  final Object source; // income, outgoing or transfer
  final int id;
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
  }

  // recalcuate the target value applying the monthly interest/inflation/growth rate
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

  // flag which transactions need to be processed for this date
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

  Simulation window(bool byMonth, int? duration, int? endAge) {
    // Earliest start date
    DateTime startDate = DateTime.now();
    if (accountList!.isNotEmpty) {
      AgeOrDate minDate = accountList!.first.amountAt;
      for (Account a in accountList!) {
        if (a.amountAt.date!.isBefore(minDate.date!)) minDate = a.amountAt;
      }
      startDate = minDate.date!;
    }

    // Determine End Date
    DateTime endDate;
    if (duration != null) {
        endDate = addYear(startDate, duration);
    } else if (endAge != null) {
        endDate = addYear(user.dob!, endAge);
    } else {
        endDate = addYear(user.dob!, maxAge); // Default 120
    }

    // Calculate total months and steps
    int totalMonth = (endDate.year - startDate.year) * 12 + (endDate.month - startDate.month);
    if (totalMonth < 1) totalMonth = 12;
    
    int answer = totalMonth;
    int step = 1;
    if (!byMonth) {
      answer = totalMonth ~/ 12;
      step = 12;
    }

    Simulation result = Simulation(this, byMonth, startDate, endDate, totalMonth, answer, step);
    return result;
  }

  SimulationResult? simulate(double volatility, double rateAdjustment, bool byMonth, int? endAge, int? durationYear) {
    if (accountList!.isEmpty) {
      return null;
    }

    // work out the window, start date, end date, number of samples to take
    final Simulation sim = window(byMonth,durationYear,endAge);

    // convert any ages into dates so its easier to process late.
    prepare();

    final pensionList = accountList!.where((a) => a.type == AccountType.pension).toList();
    final current = accountList!.where((a) => a.type == AccountType.current).toList().first;

    // Series Data
    Map<int, List<double>> accountSeries = {};
    for (Account a in accountList!) {
      if (a.id == null) continue;
      accountSeries[a.id!] = List.filled(sim.sampleCount, 0.0);
    }

    List<double> sumValue = List.filled(sim.sampleCount, 0); // sum of pensions
    List<double> incomeValue = List.filled(sim.sampleCount, 0); // Total Money IN to Current
    List<double> outgoingValue = List.filled(sim.sampleCount, 0); // Total Money OUT of Current
    List<double> intoPension = List.filled(sim.sampleCount, 0); // Net Flow into Pension (Allocated to steps)
    
    List<double> ageValue = List.generate(sim.sampleCount, (i) {
        DateTime stepDate = DateTime(sim.start.year, sim.start.month + (i * sim.step));
        return yearsBetween(user.dob!, stepDate).toDouble();
    });

    // Initialise
    Map<int,Working> working = {};
    for (Account a in accountList!) {
      if (a.id == null) continue;
      Working w = Working(a);
      working[w.source.id!] = w;
    }

    // Simulation Loop, always step by month 
    sim.begin(working);
    for (int month = 0; month < sim.monthCount; month++) {
      if (month > 0) {        
        // calculate rate for this for transactions/income/outgoing rates have already been prepared to be byMonth.
        rate();
        // flag which transactions are to be applied on this date
        mark(sim.current); 
        
        List<Transaction>? retry = [];
        for (Working w in working.values) {          
          for (Transaction t in income) {
            if (t.use) {
              Income i = t.source as Income;
              if (w.source.id==i.intoId) {
                t.taken = t.target; // just for consistency
                w.amount += t.taken!;
//                  if (pensionList.any((p) => p.id == i.intoId)) {
              }
              if (w.source.id==current.id!) {
                incomeValue[sim.sample] = incomeValue[sim.sample] + t.taken!;
              }
              if (pensionList.any((p) => p.id == i.intoId)) {
                intoPension[sim.sample] = intoPension[sim.sample] + t.taken!;
              }
            }
          }
           
          // Outgoings
          for (Transaction t in outgoing) {
            if (t.use) {
              Outgoing o = t.source as Outgoing;
              if (o.fromId==w.source.id) {
                t.taken = t.target;
                if (w.amount<t.target) 
                  t.taken = w.amount;
                w.amount -= t.taken!;
              }
              if (o.fromId==w.source.id && o.fromId==current.id!) {
                outgoingValue[sim.sample] = outgoingValue[sim.sample] + t.taken!;
              }
              if (pensionList.any((p) => p.id == o.fromId)) {
                intoPension[sim.sample] = intoPension[sim.sample] + t.taken!;
              }
            }
          }
           
          // Transfers
          for (Transaction t in transfer) {
            if (t.use) {
              Transfer r = t.source as Transfer;
              if (r.fromId==w.source.id) {
                t.taken = t.target;
                if (w.amount<t.target) 
                  t.taken = w.amount;
                w.amount -= t.taken!;
              }
              if (r.fromId==w.source.id && r.fromId==current.id!) {
                outgoingValue[sim.sample] = outgoingValue[sim.sample] + t.taken!;
              }
              if (r.intoId==w.source.id) {
                // might not have not taken from other account yet, don't know if it has this ammount left so can't do this transaction fully yet.
                retry.add(t);
              }
            }
          }
        }

        // can now do that transaction we delayed earlier as must have taken from from other account, if not then taken=0 and nothing changes
        for (Transaction t in retry) {
          Transfer r = t.source as Transfer;
          Working w = working[r.intoId]!;
          w.amount += t.taken!;
          if (r.intoId==current.id!)
            incomeValue[sim.sample] = incomeValue[sim.sample] + t.taken!;
          if (pensionList.any((p) => p.id == r.intoId)) {
            intoPension[sim.sample] = intoPension[sim.sample] + t.taken!;
          }
        }

        // Apply Interest 
        for (final w in working.values) {
          Account a = w.source;
          double rate = a.rate;
          if (pensionList.any((p) => p.id == a.id!)) 
            rate = rate + rateAdjustment; // simulate different rates for pensions, doesn't apply to savings/state pension etc
          // monthly rate = (1+annual)^(1/12) - 1
          rate = pow(1 + rate, 1.0/12.0) - 1.0;
          // step rate = (1+monthly)^(stepMonths) - 1
//          double stepRate = pow(1 + monthlyRate, stepMonth) - 1.0;
          
          w.amount *= (1.0 + rate);

          accountSeries[a.id!]![sim.sample] = w.amount;
        }
       
        double total = 0;
        for (Account a in pensionList) {
          Working w = working[a.id!]!;
          total += w.amount;
        }
        sumValue[sim.sample] = total;
      } else {
        // Step 0 - Initial State
        double total = 0;
        for (Account a in pensionList) {
          if (a.id != null) total += a.amount;
        }
        sumValue[0] = total;
      } 

      sim.next(working);
    } // month

    // MC - Adapted for Variable Steps & Flows
    // Running MC on yearly resolution usually, but here we can match steps.
    int mcRuns = 2000; // Reduced for performance with more steps
    List<double> mcMinList = List.filled(sim.sampleCount, 0.0);
    List<double> mcMaxList = List.filled(sim.sampleCount, 0.0);

    if (pensionList.isNotEmpty) {
      mcMinList = List.filled(sim.sampleCount, double.infinity);
      mcMaxList = List.filled(sim.sampleCount, double.negativeInfinity);

      List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(sim.sampleCount, 0));
      Random rand = Random();

      for (int run = 0; run < mcRuns; run++) {
         // Using simplified aggregate model for MC to be fast
         double bal = pensionList.fold(0.0, (p, c) => p + c.amount);
         mcResults[run][0] = bal;


          for (int step = 0; step < sim.sampleCount; step++) {
             double annualRate = (pensionList.first.rate) + rateAdjustment; // Approximate rate
             double sigma = volatility;
             
             // Time step in years
             double stepTimeYears = sim.step / 12.0;
             
             double stepSigma = sigma * sqrt(stepTimeYears);
             double stepMu = (log(1 + annualRate) - 0.5 * sigma * sigma) * stepTimeYears;
             
             double shock = normal(rand);
             double growth = exp(stepMu + stepSigma * shock);
             
             // Apply flow for this step (captured in deterministic run)
             bal = (bal + intoPension[step]) * growth;
             if (bal < 0) bal = 0;
             mcResults[run][step] = bal;
          }
      }
      
      for (int step = 0; step < sim.sampleCount; step++) {
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
    double lMax = 0;
    for (final w in working.values) {
      if (w.source.type!=AccountType.pension && lMax<w.maximum)
        lMax = w.maximum;
    }
  
    return SimulationResult(
        ageList: ageValue, // x - axis
        ageMin: ageValue.isNotEmpty ? ageValue.first : 0,
        ageMax: ageValue.isNotEmpty ? ageValue.last : 100,
        pensionMin: 0.0,
        pensionMax: sumMax,
        accountMin: 0.0,
        accountMax: lMax,
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
