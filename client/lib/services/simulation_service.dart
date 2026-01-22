import 'dart:math';
// Direct import of Logger, or use helper?
// The helper debugLogger exports 'log'. Let's use that.
import 'debugLogger.dart'; 

import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/simulation_result.dart';

class SimulationService {
  
  // Box-Muller transform
  static double normal(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  static SimulationResult run({
    required List<Account> accounts,
    required List<Income> incomes,
    required List<Outgoing> outgoings,
    required List<Transfer> transfers,
    required DateTime dob,
    double volatility = 0.12,
    double rateAdjustment = 0.0,
  }) {
    // We can't access instance members in static method efficiently without passing logger?
    // 'log' from debugLogger is global.
    final stopwatch = Stopwatch()..start();
    
    // ---------------------------------------------------------
    // 1. SETUP & UTILS
    // ---------------------------------------------------------
    
    // Local date helpers (replicating server properties)
    DateTime addYear(DateTime d, int years) {
      return DateTime(d.year + years, d.month, d.day);
    }
    
    // Years between dates (approx)
    double yearsBetween(DateTime from, DateTime to) {
      return (to.difference(from).inDays / 365.25);
    }
    
    if (accounts.isEmpty) {
       return SimulationResult(
           sumPotMin: 0, sumPotMax: 100, incomeMin: 0, incomeMax: 100, xAxisMin: 0, xAxisMax: 100,
           sum: [], income: [], pots: [], monteMin: [], monteMax: [], ages: [], montePaths: []
       );
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

    // ---------------------------------------------------------
    // 2. DETERMINISTIC RUN (Base Case)
    // ---------------------------------------------------------

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
            if (a.id != null && accountSeries.containsKey(a.id!)) total += accountSeries[a.id!]![y];
        }
        sumValues[y] = total;
    }

    // ---------------------------------------------------------
    // 3. MONTE CARLO SIMULATION
    // ---------------------------------------------------------
    
    int mcRuns = 300; 

    List<double> mcMin = List.filled(count, 0.0);
    List<double> mcMax = List.filled(count, 0.0);
    List<List<double>> montePaths = []; // Store all total-sum paths

    final pensionAccounts = accounts.where((a) => a.type == AccountType.pension).toList();
    
    if (pensionAccounts.isNotEmpty) {
        mcMin = List.filled(count, double.infinity);
        mcMax = List.filled(count, double.negativeInfinity);
        
        // Prepare storage for paths
        montePaths = List.generate(mcRuns, (_) => List.filled(count, 0.0));
        
        List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0.0));
        Random rand = Random();
        
        for (int run = 0; run < mcRuns; run++) {
            // Only Pension accounts are subject to volatility in this model logic
            Map<int, double> tempBalances = { for(var p in pensionAccounts) p.id! : p.amount };
            
            for(int y=0; y<count; y++) {
               double pensionTotal = 0;
               for (var p in pensionAccounts) {
                   int id = p.id!;
                   double bal = tempBalances[id]!;
                   
                   double baseRate = p.rate + rateAdjustment; 
                   double sigma = volatility; 
                   double shock = normal(rand);
                   double mu = log(1+baseRate) - 0.5*sigma*sigma;
                   bal *= exp(mu + sigma*shock);
                   
                   // Deduct Transfers Out (Simple Logic: Only check transfers explicitly FROM pension accounts)
                   for(var tr in transfers) {
                       if (tr.fromAccount == id && isInRange(y, tr.startAt, tr.endAt)) {
                           double amt = tr.amount * 12;
                           if (bal < amt) amt = bal;
                           bal -= amt;
                       }
                   }
                   if(bal < 0) bal=0;
                   tempBalances[id] = bal;
                   pensionTotal += bal;
               }
               
               double nonPensionTotal = 0;
               // Get non-pension total from the deterministic run for this year
               for (var a in accounts) {
                   if (a.type != AccountType.pension && a.id != null) {
                       nonPensionTotal += accountSeries[a.id!]![y];
                   }
               }
               
               double totalWealth = pensionTotal + nonPensionTotal;
               mcResults[run][y] = totalWealth;
            }
        }
        
        montePaths = mcResults;

        // Calc P25 and P75 for IQR
        for(int y=0; y<count; y++) {
             List<double> yearValues = [];
             for(int r=0; r<mcRuns; r++) {
                 yearValues.add(mcResults[r][y]);
             }
             yearValues.sort();
             
             if (yearValues.isNotEmpty) {
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
    
    stopwatch.stop();
    glog.info('SimulationService: $count years simulated in ${stopwatch.elapsedMilliseconds}ms'); 
    
    return SimulationResult(
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
        montePaths: montePaths, // Pass the full paths
        ages: ages
    );
  }
}
