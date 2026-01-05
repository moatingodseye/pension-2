import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MonteCarloApp());
}

class MonteCarloApp extends StatelessWidget {
  const MonteCarloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MonteCarloPage(),
    );
  }
}

/* ───────────────────────────
   MONTE CARLO ENGINE
─────────────────────────── */

class MonteCarloResult {
  final List<List<double>> paths;
  final List<double> finalValues;

  MonteCarloResult(this.paths, this.finalValues);
}

MonteCarloResult runMonteCarlo({
  required double initialPot,
  required int years,
  required int simulations,
  required double annualReturn,
  required double annualVolatility,
  required double monthlyContribution,
}) {
  final rand = Random();
  final months = years * 12;

  final mu = annualReturn;
  final sigma = annualVolatility;

  final monthlyMu = (mu - 0.5 * sigma * sigma) / 12;
  final monthlySigma = sigma / sqrt(12);

  double randomNormal() {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  final paths = List.generate(
    simulations,
    (_) => List.filled(months + 1, initialPot),
  );

  final finalValues = List.filled(simulations, 0.0);

  for (int s = 0; s < simulations; s++) {
    for (int m = 1; m <= months; m++) {
      final shock = randomNormal();
      final growth = exp(monthlyMu + monthlySigma * shock);

      paths[s][m] =
          paths[s][m - 1] * growth + monthlyContribution;
    }
    finalValues[s] = paths[s].last;
  }

  return MonteCarloResult(paths, finalValues);
}

/* ───────────────────────────
   UI PAGE
─────────────────────────── */

class MonteCarloPage extends StatefulWidget {
  const MonteCarloPage({super.key});

  @override
  State<MonteCarloPage> createState() => _MonteCarloPageState();
}

class _MonteCarloPageState extends State<MonteCarloPage> {
  MonteCarloResult? result;

  void runSimulation() {
    final r = runMonteCarlo(
      initialPot: 100000,
      years: 10,
      simulations: 10000,
      annualReturn: 0.07,
      annualVolatility: 0.15,
      monthlyContribution: 500,
    );

    setState(() => result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monte Carlo Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: runSimulation,
              child: const Text('Run Simulation'),
            ),
            const SizedBox(height: 16),
            if (result != null)
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: PathChart(result!.paths)),
                    Expanded(child: Histogram(result!.finalValues)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────────
   PATH CHART
─────────────────────────── */

class PathChart extends StatelessWidget {
  final List<List<double>> paths;

  const PathChart(this.paths, {super.key});

  @override
  Widget build(BuildContext context) {
    final sampled = paths.take(50).toList();

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: false),
        lineBarsData: sampled.map((path) {
          return LineChartBarData(
            spots: [
              for (int i = 0; i < path.length; i++)
                FlSpot(i.toDouble(), path[i])
            ],
            dotData: FlDotData(show: false),
            isCurved: false,
            color: Colors.blue.withOpacity(0.15),
          );
        }).toList(),
      ),
    );
  }
}

/* ───────────────────────────
   HISTOGRAM
─────────────────────────── */

class Histogram extends StatelessWidget {
  final List<double> values;

  const Histogram(this.values, {super.key});

  @override
  Widget build(BuildContext context) {
    values.sort();

    const bins = 40;
    final min = values.first;
    final max = values.last;
    final binSize = (max - min) / bins;

    final counts = List.filled(bins, 0);

    for (final v in values) {
      final i = ((v - min) / binSize).floor().clamp(0, bins - 1);
      counts[i]++;
    }

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(show: false),
        barGroups: List.generate(bins, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: Colors.green,
              )
            ],
          );
        }),
      ),
    );
  }
}
