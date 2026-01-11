import 'dart:math';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'db.dart';
import 'date.dart';

// Box-Muller transform to generate a standard normal (mean=0, std=1)
double normal(Random rand) {
  final u1 = rand.nextDouble();
  final u2 = rand.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}

Future<Response> simulate(Request req) async {
  final Database db = pension.getDb();
  final uid = req.context['uid'];
  final users = db.select("SELECT * FROM users WHERE id=?", [uid]);
  if (users.isEmpty) return Response.notFound('User not found');
  final user = users.first;
  final dob = DateTime.parse(user['dob']);

  // Fetch pension pots, drawdowns, state pensions, and user
  final pots = db.select("SELECT * FROM pension_pots WHERE user_id=?", [uid]);
  final drawdowns = db.select("SELECT * FROM drawdowns WHERE user_id=?", [uid]);
  final statePensions = db.select("SELECT * FROM state_pensions WHERE user_id=?", [uid]);

  if (pots.isEmpty) {
    return Response.ok(jsonEncode({
    'success': true,
    'data': {
      'pots': [],
      'sum': [],
      'income': [],
      'monte_min': [],
      'monte_max': [],
      'startAge': 0,
      'count': 0,
    }
  }), headers: {'Content-Type': 'application/json'});
  }

  const int maxYear = 120;
  final int endYearOffset = maxYear-(dob.year-1900); // dob + this is end of chart, start is first pot date.

  // Determine simulation start
  DateTime earliestPotDate = pots.map((p) => DateTime.parse(p['date'])).reduce((a,b) => a.isBefore(b)?a:b);
  DateTime endDate = addYear(earliestPotDate,endYearOffset);
  DateTime startDate = earliestPotDate;
  int startAge = yearsBetween(dob, earliestPotDate).toInt();
  int count = yearsBetween(startDate,endDate).toInt(); // temporarily do it in years not months

  // Prepare deterministic data
  List<List<double>> pot = List.generate(pots.length, (_) => List.filled(count, 0));
  List<int> id = List.filled(pots.length,0);
  List<double> sumValues = List.filled(count, 0);
  List<double> incomeValues = List.filled(count, 0);
  Map<int,double> drawn = <int,double>{}; // drawdownid, last drawnvalue
  Map<int,Map<int,double>> draw = <int,Map<int,double>>{}; // pot_id, year, drawn amount

  // Initialize pot balances
  for (int i=0;i<pots.length;i++){
    pot[i][0] = pots[i]['amount'] as double;
    id[i] = pots[i]['id'] as int;
  }

  // Monthly deterministic calculation
  for (int y=0;y<count;y++){
    double yearSum=0;
    double yearIncome=0;

//    DateTime currentMonth = earliestPotDate.add(Duration(days: m*30)); //uuuk lost 5 days a year!

    // Pots
    for (int i=0;i<pots.length;i++){
      if (y>0) pot[i][y] = pot[i][y-1];

      // current year
      DateTime current = addYear(earliestPotDate,y);

      // Apply drawdowns
      for (var d in drawdowns){
        if (d['pension_pot_id']==pots[i]['id']){
          DateTime start = DateTime.parse(d['start_date']);
          DateTime? end = d['end_date'] != null ? DateTime.parse(d['end_date']) : null;
          if (!current.isBefore(start) && (end==null || !current.isAfter(end))) {
            double amt;
            if (drawn.containsKey(d['id'])) {
              amt = drawn[d['id']]!;
              amt *= (1 + ((d['interest_rate'] as double))); 
            } else {
              amt = (d['amount'] as double)*12;
            }
            if (pot[i][y] < amt) {
              amt = pot[i][y];
            }
            drawn[d['id']] = amt;
            pot[i][y] -= amt;
            yearIncome += amt;
          }
        }
      }

      // record income for
      Map<int,double> map;
      if (draw.containsKey(id[i])) {
        map = draw[id[i]] as Map<int,double>;
      } else {
        map = <int,double>{};
        draw[id[i]] = map;
      }
      map[y] = yearIncome;

      // Yearly interest      
      double rate = (pots[i]['interest_rate'] as double);
      pot[i][y] *= 1 + rate;

      yearSum += pot[i][y];
    }

    // State pension
    if (statePensions.isNotEmpty){
      var sp = statePensions.first;      
      int start = sp['start_age'] as int;
      int userAge = startAge + y;
      if (userAge >= start){
        yearIncome += 12 * (sp['amount'] as double);
      }
    }

    sumValues[y] = yearSum;
    incomeValues[y] = yearIncome;
  }

  // Monte Carlo simulation
  int mcRuns = 20000;
  List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));
  Random rand = Random();

  for (int run=0; run<mcRuns; run++){
    List<double> mcPots = pots.map((p)=>p['amount'] as double).toList();
    for (int y=0;y<count;y++) {
      double total=0;
      for (int i=0;i<mcPots.length;i++) {
//        if (y>0)
//          mcPots[i][y] = mcPots[i][y-1];

        // Apply drawdowns same as deterministic
        Map<int,double> map = draw[id[i]] as Map<int,double>;
        mcPots[i] -= map[y] as double;

        // Yearly interest plus random normal variation
        //double noise = rand.nextDouble() * 0.24 - 0.12; // ±12% per year
        //mcPots[i] *= (1 + noise);  // Apply correctly scaled APR

        double sigma = 0.12;
        double shock = normal(rand);
        double noise = -0.5 * sigma * sigma + sigma * shock;
        mcPots[i] *= exp(noise);


        if (mcPots[i]<0) mcPots[i]=0;
        total+=mcPots[i];
      }
      mcResults[run][y]=total;
    }
  }

  // Compute Monte Carlo min/max safely
  List<double> mcMin = List.filled(count, double.infinity);
  List<double> mcMax = List.filled(count, double.negativeInfinity);
  for (int y = 0; y < count; y++) {
    for (int run = 0; run < mcRuns; run++) {
      mcMin[y] = min(mcMin[y], mcResults[run][y]);
      mcMax[y] = max(mcMax[y], mcResults[run][y]);
    }
  }

  // Return JSON
  return Response.ok(jsonEncode({
    'success': true,
    'data': {
      'pots': pot,
      'id': id,
      'sum': sumValues,
      'income': incomeValues,
      'monte_min': mcMin,
      'monte_max': mcMax,
      'age': startAge,
      'count': count
    }
  }), headers: {'Content-Type':'application/json'});
}

/*

import 'dart:math';

/// Generate a standard normal random number using Box-Muller
double normal(Random rand) {
  final u1 = rand.nextDouble();
  final u2 = rand.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}

/// Linear interpolation for percentiles
double percentile(List<double> sorted, double p) {
  double pos = (sorted.length - 1) * p;
  int lower = pos.floor();
  int upper = pos.ceil();
  if (lower == upper) return sorted[lower];
  return sorted[lower] + (pos - lower) * (sorted[upper] - sorted[lower]);
}

// Monte Carlo simulation
void runMonteCarlo({
  required List<Map<String, dynamic>> pots,
  required Map<int, Map<int, double>> draw,
  required int count,
  required int mcRuns,
  required double sigma, // annual volatility e.g., 0.12 for 12%
  required Random rand,
  required List<double> mc25,
  required List<double> mc75,
}) {
  // Store all MC results temporarily
  List<List<double>> mcResults = List.generate(mcRuns, (_) => List.filled(count, 0));

  for (int run = 0; run < mcRuns; run++) {
    // Start with initial pot balances
    List<double> mcPots = pots.map((p) => p['amount'] as double).toList();

    for (int y = 0; y < count; y++) {
      double total = 0;

      for (int i = 0; i < mcPots.length; i++) {
        // Apply drawdowns (same as deterministic)
        Map<int, double> map = draw[pots[i]['id'] as int]!;
        mcPots[i] -= map[y] ?? 0;

        if (mcPots[i] < 0) mcPots[i] = 0;

        // Apply stochastic return using lognormal (geometrically unbiased)
        double shock = normal(rand);
        double noise = -0.5 * sigma * sigma + sigma * shock;
        mcPots[i] *= exp(noise);

        if (mcPots[i] < 0) mcPots[i] = 0;

        total += mcPots[i];
      }

      mcResults[run][y] = total;
    }
  }

  // Compute 25% and 75% percentiles for each year
  for (int y = 0; y < count; y++) {
    List<double> yearResults = List.generate(mcRuns, (r) => mcResults[r][y]);
    yearResults.sort();
    mc25[y] = percentile(yearResults, 0.25);
    mc75[y] = percentile(yearResults, 0.75);
  }
}

*/