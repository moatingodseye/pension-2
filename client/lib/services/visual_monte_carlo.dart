import 'dart:math';

class VisualMonteCarlo {
  
  static List<List<double>> generateMonteCarloPaths({
    required List<double> sumList, // Main simulation sum line
    required List<double> annualNetFlow, // Net flow into pot per step
    required double volatility,
    required double rateAdjustment,
    int numPaths = 50,
    int stepMonths = 12,
  }) {
    if (sumList.isEmpty) return [];

    final rand = Random();
    final count = sumList.length;
    final startingSum = sumList.first;

    // We generate paths starting from the same initial pot
    List<List<double>> paths = List.generate(numPaths, (_) => List.filled(count, 0.0));

    for (int p = 0; p < numPaths; p++) {
      double bal = startingSum;
      paths[p][0] = bal;

      for (int step = 1; step < count; step++) {
        // Approximate parameters for this step
        // We don't have per-account rates here, so we assume a generic "market" rate
        // derived roughly from the trend or a fixed average (e.g. 5-7%) modified by adjustment.
        // Better: Use the implied rate from the sumList change? 
        // Or just use a fixed assumption since it's "Visual Cloud".
        // Let's use 5% base + adjustment.
        double baseRate = 0.05 + rateAdjustment;
        
        double stepTimeYears = stepMonths / 12.0;
        double sigma = volatility;
        double stepSigma = sigma * sqrt(stepTimeYears);
        double stepMu = (log(1 + baseRate) - 0.5 * sigma * sigma) * stepTimeYears;
        
        double shock = sqrt(-2 * log(rand.nextDouble())) * cos(2 * pi * rand.nextDouble());
        double growth = exp(stepMu + stepSigma * shock);

        // Apply flow (Income/Outgoing/Transfers for this step)
        double flow = (step < annualNetFlow.length) ? annualNetFlow[step] : 0.0;
        
        bal = (bal + flow) * growth;
        if (bal < 0) bal = 0;
        
        paths[p][step] = bal;
      }
    }
    
    return paths;
  }
}
