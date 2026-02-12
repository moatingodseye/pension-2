import 'dart:math';

class MonteCarloResult {
  /// Selected paths for display (e.g. 50 paths)
  final List<List<double>> paths;
  
  /// 10th Percentile path (pessimistic)
  final List<double> percentile10;
  
  /// 50th Percentile path (median)
  final List<double> median;
  
  /// 90th Percentile path (optimistic)
  final List<double> percentile90;
  
  /// All final values from the simulation (for histogram)
  final List<double> finalValues;

  MonteCarloResult({
    required this.paths,
    required this.percentile10,
    required this.median,
    required this.percentile90,
    required this.finalValues,
  });

  Map<String, dynamic> toJson() => {
    'paths': paths,
    'percentile10': percentile10,
    'median': median,
    'percentile90': percentile90,
    'finalValues': finalValues,
  };

  factory MonteCarloResult.fromJson(Map<String, dynamic> json) {
    return MonteCarloResult(
      paths: (json['paths'] as List).map((e) => (e as List).map((v) => (v as num).toDouble()).toList()).toList(),
      percentile10: (json['percentile10'] as List).map((e) => (e as num).toDouble()).toList(),
      median: (json['median'] as List).map((e) => (e as num).toDouble()).toList(),
      percentile90: (json['percentile90'] as List).map((e) => (e as num).toDouble()).toList(),
      finalValues: (json['finalValues'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

double _percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return 0.0;
  final n = sorted.length;
  final rank = p * (n - 1);
  final lo = rank.floor();
  final hi = rank.ceil();
  if (lo == hi) return sorted[lo];
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (rank - lo);
}

/// Runs a Monte Carlo simulation.
/// [initialPot] - Starting value.
/// [years] - Duration in years.
/// [simulations] - Total number of runs (e.g. 2000).
/// [annualReturn] - Expected mean return (e.g. 0.05 for 5%).
/// [annualVolatility] - Standard deviation (e.g. 0.15 for 15%).
/// [monthlyContribution] - Amount added/removed per month.
/// [stepsPerYear] - Resolution of the result (1 for yearly, 12 for monthly).
/// [displayPaths] - Number of raw paths to return for 'spaghetti' chart.
MonteCarloResult runMonteCarlo({
  required double initialPot,
  required int years,
  required int simulations,
  required double annualReturn,
  required double annualVolatility,
  required double monthlyContribution,
  int stepsPerYear = 1, 
  int displayPaths = 50,
}) {
  final rand = Random();
  final totalSteps = years * stepsPerYear;
  
  // Calculate drift and diffusion for the step size
  // If we want to simulate monthly steps but only record yearly, we still simulate monthly?
  // User asked for "aesthetic". To keep it simple but accurate:
  // We simulate at the resolution requested.
  
  final dt = 1.0 / stepsPerYear;
  final drift = (annualReturn - 0.5 * annualVolatility * annualVolatility) * dt;
  final vol = annualVolatility * sqrt(dt);
  final contributionPerStep = monthlyContribution * (12.0 / stepsPerYear);

  List<List<double>> allPaths = List.generate(
    simulations,
    (_) => List<double>.filled(totalSteps + 1, 0.0),
  );

  List<double> finalValues = List<double>.filled(simulations, 0.0);

  // Run Simulations
  for (int s = 0; s < simulations; s++) {
    allPaths[s][0] = initialPot;
    double current = initialPot;
    
    for (int t = 1; t <= totalSteps; t++) {
      // Box-Muller for normal distribution
      double u1 = 1.0 - rand.nextDouble(); // avoid 0
      double u2 = 1.0 - rand.nextDouble();
      double z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      
      double growth = exp(drift + vol * z);
      current = current * growth + contributionPerStep;
      if (current < 0) current = 0; // No negative pension pots in this model
      
      allPaths[s][t] = current;
    }
    finalValues[s] = current;
  }

  // Calculate Percentiles per time step
  List<double> p10 = List.filled(totalSteps + 1, 0.0);
  List<double> p50 = List.filled(totalSteps + 1, 0.0);
  List<double> p90 = List.filled(totalSteps + 1, 0.0);

  for (int t = 0; t <= totalSteps; t++) {
    List<double> valuesAtStep = [];
    for (int s = 0; s < simulations; s++) {
      valuesAtStep.add(allPaths[s][t]);
    }
    valuesAtStep.sort();
    p10[t] = _percentile(valuesAtStep, 0.10);
    p50[t] = _percentile(valuesAtStep, 0.50);
    p90[t] = _percentile(valuesAtStep, 0.90);
  }

  // Select a subset of paths for display
  // We take the first N, or random N. Since they are all random, taking first N is fine.
  List<List<double>> subsetPaths = [];
  for(int i=0; i<min(simulations, displayPaths); i++) {
    subsetPaths.add(allPaths[i]);
  }

  return MonteCarloResult(
    paths: subsetPaths,
    percentile10: p10,
    median: p50,
    percentile90: p90,
    finalValues: finalValues,
  );
}
