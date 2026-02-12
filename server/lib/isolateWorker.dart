import 'dart:isolate';
import 'package:shared/models.dart';
import 'package:shared/logic.dart';

class SimulationRequest {
  final SendPort sendPort;
  final List<Map<String, dynamic>> accounts; // Account JSONs

  SimulationRequest(this.sendPort, this.accounts);
}

class SimulationResponse {
  final Map<int, MonteCarloResult> results;

  SimulationResponse(this.results);
}

void simulationWorker(SimulationRequest request) {
  final results = <int, MonteCarloResult>{};

  for (final accJson in request.accounts) {
    // Basic mapping from JSON to account parameters
    // In a real app we'd deserialize to Account model first
    final id = accJson['id'] as int;
    final amount = (accJson['amount'] as num).toDouble();
    final rate = (accJson['rate'] as num).toDouble();
    
    // Configurable parameters could be passed in request
    final result = runMonteCarlo(
      initialPot: amount,
      years: 30, // Default 30 years
      simulations: 2000,
      annualReturn: rate,
      annualVolatility: 0.15, // Default volatility
      monthlyContribution: 0, // Simplified for now
      stepsPerYear: 1,
      displayPaths: 50
    );

    results[id] = result;
  }

  request.sendPort.send(SimulationResponse(results));
}
