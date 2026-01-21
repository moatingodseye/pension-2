import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SimulationChart extends StatelessWidget {
  final List<double> sumPot;
  final List<double> income;
  final List<List<double>> pots;
  final List<double> mcMin;
  final List<double> mcMax;
  final List<double> ages;
  final List<bool> showLines;

  final double sumPotMin;
  final double sumPotMax;
  final double incomeMin;
  final double incomeMax;
  final double xAxisMin;
  final double xAxisMax;
  // removed isIncomeChart

  const SimulationChart({
    super.key,
    required this.sumPot,
    required this.income,
    required this.pots,
    required this.mcMin,
    required this.mcMax,
    required this.ages,
    required this.showLines,
    required this.sumPotMin,
    required this.sumPotMax,
    required this.incomeMin,
    required this.incomeMax,
    required this.xAxisMin,
    required this.xAxisMax,
  });

  final List<List<double>>? montePaths; // New parameter

  const SimulationChart({
    super.key,
    required this.sumPot,
    required this.income,
    required this.pots,
    required this.mcMin,
    required this.mcMax,
    this.montePaths, // Optional
    required this.ages,
    required this.showLines,
    required this.sumPotMin,
    required this.sumPotMax,
    required this.incomeMin,
    required this.incomeMax,
    required this.xAxisMin,
    required this.xAxisMax,
  });

  @override
  Widget build(BuildContext context) {
    // Normalization Factor: Map Income Range (0..incomeMax) to Pot Range (0..sumPotMax)
    // Visual Value = Real Income * Factor
    final double incomeFactor = (incomeMax == 0) ? 1.0 : (sumPotMax / incomeMax);

    List<LineChartBarData> lines = [];

    // 0. VISUAL CLOUD (Client-Side Monte Carlo) - Render First (Background)
    if (montePaths != null && montePaths!.isNotEmpty && showLines.length > 2 && showLines[2]) {
      // Sample if too many to prevent UI freeze? User asked for "thousands" but FL Chart might struggle.
      // Let's render as is, efficiently.
      for (var path in montePaths!) {
        if (path.length <= ages.length) {
          lines.add(LineChartBarData(
            spots: path.asMap().entries.map((e) => FlSpot(ages[e.key], e.value)).toList(),
            isCurved: false, // Straight lines for cloud usually look better/performant
            color: Colors.blue.withOpacity(0.03), // Very low opacity for density
            barWidth: 1,
            dotData: FlDotData(show: false),
             // No tooltips for individual cloud lines
            belowBarData: BarAreaData(show: false),
          ));
        }
      }
    }

    // 1. Monte Carlo shaded area (Pot Scale)
    if (showLines.length > 2 && showLines[2] && mcMin.isNotEmpty && mcMax.isNotEmpty && ages.length >= mcMin.length) {
      lines.add(LineChartBarData(
        spots: mcMax.asMap().entries.map((e) => FlSpot(ages[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.grey.withOpacity(0.3),
        barWidth: 0,
        belowBarData: BarAreaData(show: true, color: Colors.grey.withOpacity(0.3)),
        dotData: FlDotData(show: false),
      ));
      lines.add(LineChartBarData(
        spots: mcMin.asMap().entries.map((e) => FlSpot(ages[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        belowBarData: BarAreaData(show: true, color: Colors.grey.withOpacity(0.3)),
        dotData: FlDotData(show: false),
      ));
    }

    // 2. Individual pots (Pot Scale)
    for (int i = 0; i < pots.length; i++) {
      if (i + 3 < showLines.length && showLines[i + 3] && pots[i].isNotEmpty && ages.length >= pots[i].length) {
        lines.add(LineChartBarData(
          spots: pots[i].asMap().entries.map((e) => FlSpot(ages[e.key], e.value)).toList(),
          isCurved: true,
          color: Colors.primaries[i % Colors.primaries.length].withOpacity(0.5),
          barWidth: 2,
          dotData: FlDotData(show: false),
        ));
      }
    }

    // 3. Sum Pot (Pot Scale)
    if (showLines[0] && sumPot.isNotEmpty && ages.length >= sumPot.length) {
      lines.add(LineChartBarData(
        spots: sumPot.asMap().entries.map((e) => FlSpot(ages[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        dotData: FlDotData(show: false),
      ));
    }

    // 4. Income (Normalized Scale -> Visual: Pot Scale)
    // We plot: Real Income * Factor
    if (showLines[1] && income.isNotEmpty && ages.length >= income.length) {
      lines.add(LineChartBarData(
        spots: income.asMap().entries
            .map((e) => FlSpot(ages[e.key], e.value * incomeFactor))
            .toList(),
        isCurved: true,
        color: Colors.orange,
        barWidth: 3,
        dotData: FlDotData(show: false),
        dashArray: [5, 5], // Dashed line for distinction
      ));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height * 0.7,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          lineBarsData: lines,
          minY: sumPotMin, // Base Scale Min
          maxY: sumPotMax, // Base Scale Max
          minX: xAxisMin,
          maxX: xAxisMax,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (xAxisMax - xAxisMin) / 10,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Pension Value (£)", style: TextStyle(color: Colors.blue)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: sumPotMax / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value), 
                    style: const TextStyle(color: Colors.blue, fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: const Text("Income (£)", style: TextStyle(color: Colors.orange)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: sumPotMax / 5, // Use same visual interval steps
                getTitlesWidget: (value, meta) {
                  // Denormalize: Label = Value / Factor
                  final realIncome = value / incomeFactor;
                  return Text(
                    _formatCurrency(realIncome),
                    style: const TextStyle(color: Colors.orange, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: true,
            horizontalInterval: sumPotMax / 10,
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  // Identify Income line by its unique dashArray property
                  bool isIncomeLine = spot.bar.dashArray != null;
                  
                  double value = spot.y;
                  String label = "Pot";
                  Color color = spot.bar.color ?? Colors.blue;

                  if (isIncomeLine) {
                    value = spot.y / incomeFactor; // Denormalize
                    label = "Income";
                    color = Colors.orange;
                  } else if (spot.bar.barWidth == 0) {
                     label = "MC";
                  }

                  return LineTooltipItem(
                    "$label: ${_formatCurrency(value)}",
                    TextStyle(color: color, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
  
  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value/1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value/1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}
