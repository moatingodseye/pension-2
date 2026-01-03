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
  final bool isIncomeChart;

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
    required this.isIncomeChart, 
  });

  @override
  Widget build(BuildContext context) {
    double maxPot = sumPot.isNotEmpty ? sumPot.reduce((a, b) => a > b ? a : b) : sumPotMax;
    double maxIncome = income.isNotEmpty ? income.reduce((a, b) => a > b ? a : b) : incomeMax;

    List<LineChartBarData> lines = [];

    // **For Pot Chart** (when isIncomeChart is false)
    if (!isIncomeChart) {
      if (showLines[0] && sumPot.isNotEmpty && ages.length >= sumPot.length) {
        lines.add(LineChartBarData(
          spots: sumPot.asMap().entries
              .map((e) => FlSpot(ages[e.key], e.value))
              .toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: FlDotData(show: false),
        ));
      }

      // Individual pots
      for (int i = 0; i < pots.length; i++) {
        if (i + 3 < showLines.length && showLines[i + 3] && pots[i].isNotEmpty && ages.length >= pots[i].length) {
          lines.add(LineChartBarData(
            spots: pots[i].asMap().entries
                .map((e) => FlSpot(ages[e.key], e.value))
                .toList(),
            isCurved: true,
            color: Colors.primaries[i % Colors.primaries.length],
            barWidth: 2,
            dotData: FlDotData(show: false),
          ));
        }
      }

      // Monte Carlo shaded area
      if (showLines.length > 2 && showLines[2] && mcMin.isNotEmpty && mcMax.isNotEmpty && ages.length >= mcMin.length) {
        lines.add(LineChartBarData(
          spots: mcMax.asMap().entries
              .map((e) => FlSpot(ages[e.key], e.value))
              .toList(),
          isCurved: true,
          color: Colors.grey.withOpacity(0.3),
          barWidth: 0,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.grey.withOpacity(0.3),
          ),
          dotData: FlDotData(show: false),
        ));
        lines.add(LineChartBarData(
          spots: mcMin.asMap().entries
              .map((e) => FlSpot(ages[e.key], e.value))
              .toList(),
          isCurved: true,
          color: Colors.transparent,
          barWidth: 0,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.grey.withOpacity(0.3),
          ),
          dotData: FlDotData(show: false),
        ));
      }

    }

    // **For Income Chart** (when isIncomeChart is true)
    if (isIncomeChart) {
      if (showLines[1] && income.isNotEmpty && ages.length >= income.length) {
        lines.add(LineChartBarData(
          spots: income.asMap().entries
              .map((e) => FlSpot(ages[e.key], e.value)) // Real income values
              .toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 2,
          dotData: FlDotData(show: false),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height * 0.7,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          lineBarsData: lines,
          minY: isIncomeChart ? incomeMin : sumPotMin,
          maxY: isIncomeChart ? incomeMax : sumPotMax,
          minX: xAxisMin,
          maxX: xAxisMax,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (xAxisMax - xAxisMin) / 10,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(value.toStringAsFixed(0));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !isIncomeChart, // Show on the pot chart
                interval: 100000, // Step size for pots
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0));
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: isIncomeChart, // Show on the income chart
                interval: 10000, // Step size for income
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0));
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  String tooltipValue = isIncomeChart 
                    ? "Income: ${touchedSpot.y.toStringAsFixed(2)}" 
                    : "Pot: ${touchedSpot.y.toStringAsFixed(2)}";
                  return LineTooltipItem(
                    tooltipValue,
                    TextStyle(color: Colors.white, fontSize: 12),
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
}
