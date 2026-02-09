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

double percentile(List<double> sorted, double p) {
  final n = sorted.length;
  final rank = p * (n - 1);
  final lo = rank.floor();
  final hi = rank.ceil();
  if (lo == hi) return sorted[lo];
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (rank - lo);
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
      years: 100,
      simulations: 300,
      annualReturn: 0.04,
      annualVolatility: 0.15,
      monthlyContribution: 0,
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

FlTitlesData title() {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 60,
        interval: 50000,
        getTitlesWidget: (value, meta) {
          return Text(
            '£${(value / 1000).toStringAsFixed(0)}k',
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 60, // 5 years
        getTitlesWidget: (value, meta) {
          return Transform.rotate(
            angle: -0.5, // radians (~30°)
            child: Text(
              '${(value / 12).round()}y',
              style: const TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    ),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

class PathChart extends StatelessWidget {
  final List<List<double>> paths;

  const PathChart(this.paths, {super.key});

  @override
  Widget build(BuildContext context) {
    final months = paths.first.length;

    final p10 = <FlSpot>[];
    final p50 = <FlSpot>[];
    final p90 = <FlSpot>[];

    for (int m = 0; m < months; m++) {
      final valuesAtMonth = paths.map((p) => p[m]).toList()..sort();

      p10.add(FlSpot(m.toDouble(), percentile(valuesAtMonth, 0.10)));
      p50.add(FlSpot(m.toDouble(), percentile(valuesAtMonth, 0.50)));
      p90.add(FlSpot(m.toDouble(), percentile(valuesAtMonth, 0.90)));
    }

    final spaghetti = paths.take(300).map((path) {
      return LineChartBarData(
        spots: [
          for (int i = 0; i < path.length; i++)
            FlSpot(i.toDouble(), path[i])
        ],
        isCurved: false,
        dotData: FlDotData(show: false),
        color: Colors.blue.withOpacity(0.05),
        barWidth: 1,
      );
    }).toList();

    final p90Line = LineChartBarData(
      spots: p90,
      isCurved: false,
      dotData: FlDotData(show: false),
      color: Colors.transparent,
      belowBarData: BarAreaData(
        show: true,
        color: Colors.green.withOpacity(0.25),
      ),
    );

    final p10Line = LineChartBarData(
      spots: p10,
      isCurved: false,
      dotData: FlDotData(show: false),
      color: Colors.transparent,
    );

    final p90Outline = LineChartBarData(
      spots: p90,
      color: Colors.red.shade800,
      barWidth: 1,
      dotData: FlDotData(show: false),
    );

    final p10Outline = LineChartBarData(
      spots: p10,
      color: Colors.green.shade800,
      barWidth: 1,
      dotData: FlDotData(show: false),
    );

    final medianLine = LineChartBarData(
      spots: p50,
      isCurved: false,
      dotData: FlDotData(show: false),
      color: Colors.amber,
      barWidth: 2,
    );

    return ClipRect(child: LineChart(
      LineChartData(
        minY: 0,
        maxY: 500000,
        titlesData: title(),
        lineBarsData: [
          ...spaghetti, // background noise
//          p90Line,      // band top
//          p10Line,      // band bottom
          p90Outline,
          p10Outline,
          medianLine,   // central tendency
        ],
        lineTouchData: LineTouchData(enabled:false),
      ),
    ));

/*
//    final sampled = paths.take(50).toList();
    final all = paths.expand((p) => p);
    final minY = all.reduce(min);
    final maxY = all.reduce(max);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: 200000,
        titlesData: FlTitlesData(show: false),
        lineBarsData: paths.map((path) {
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
*/
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
