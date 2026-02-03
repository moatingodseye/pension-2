import '../services/visual_monte_carlo.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared/models/date.dart';

class SimulationChart extends StatelessWidget {
  final List<String> nameList;
  final List<double> sumList;
  final List<double> incomeList; 
  final List<double> outgoingList;
  final List<double> intoPensionList; // New
  final List<List<double>> accountMap;
  final List<double> mcMinList;
  final List<double> mcMaxList;
  final List<double> ageList;
  final DateTime dob;
  final List<bool> showList;

  final double pensionMin;
  final double pensionMax;
  final double accountMin;
  final double accountMax;
  final double ageMin;
  final double ageMax;
  final List<List<double>>? montePath; // Can be passed or generated

  const SimulationChart({
    super.key,
    required this.nameList,
    required this.sumList,
    required this.incomeList,
    required this.outgoingList,
    required this.accountMap,
    required this.mcMinList,
    required this.mcMaxList,
    this.montePath,
    required this.ageList,
    required this.showList,
    required this.pensionMin,
    required this.pensionMax,
    required this.accountMin,
    required this.accountMax,
    required this.ageMin,
    required this.ageMax,
    required this.dob,
    this.intoPensionList = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Normalization Factor: Map Income Range (0..incomeMax) to Pot Range (0..sumPotMax)
    // Visual Value = Real Income * Factor
    final double factor = (accountMax == 0) ? 1.0 : (pensionMax / accountMax);

    List<String> name = []; // names of lines as added so can be used in popup
    List<LineChartBarData> line = [];

    // 0. VISUAL CLOUD (Client-Side Monte Carlo) - Render First (Background)
    // If passed explicitly or generate if annualNetFlow is available
    List<List<double>> cloudPaths = montePath ?? [];
    
    if ((cloudPaths.isEmpty) && intoPensionList.isNotEmpty && sumList.isNotEmpty && showList.length > 2 && showList[2]) {
        // Generate locally for visualization
        // We assume 12 steps per year approx for visual adjustment if not passed, but let's default to standard
        // Does step match? 
        int steps = sumList.length > 1 ? sumList.length : 12;
        int years = (ageMax - ageMin).toInt();
        int stepMonths = years > 0 ? (12 * years / steps).round() : 12;
        if (stepMonths < 1) stepMonths = 1;
        
        cloudPaths = VisualMonteCarlo.generateMonteCarloPaths(
            sumList: sumList,
            annualNetFlow: intoPensionList, 
            volatility: 0.12, // Visual default? Or access provider?
            rateAdjustment: 0.0,
            stepMonths: stepMonths
        );
    }
    
    if (cloudPaths.isNotEmpty && showList.length > 2 && showList[2]) {
      for (var path in cloudPaths) {
        if (path.length <= ageList.length) {
          // name.add('Age'); // Don't match tooltip
          line.add(LineChartBarData(
            spots: path.asMap().entries.map((e) => FlSpot(ageList[e.key], e.value)).toList(),
            isCurved: false,
            color: Colors.blue.withOpacity(0.15), // Faded blue as requested
            barWidth: 1,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ));
        }
      }
    }

    // 1. Monte Carlo shaded area (Pot Scale)
    if (showList.length > 2 && showList[2] && mcMinList.isNotEmpty && mcMaxList.isNotEmpty && ageList.length >= mcMinList.length) {
      name.add('Max');
      line.add(LineChartBarData(
        spots: mcMaxList.asMap().entries.map((e) => FlSpot(ageList[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.grey.withOpacity(0.3),
        barWidth: 0,
        belowBarData: BarAreaData(show: true, color: Colors.grey.withOpacity(0.3)),
        dotData: FlDotData(show: false),
      ));
      name.add('Min');
      line.add(LineChartBarData(
        spots: mcMinList.asMap().entries.map((e) => FlSpot(ageList[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        belowBarData: BarAreaData(show: true, color: Colors.grey.withOpacity(0.3)),
        dotData: FlDotData(show: false),
      ));
    }

    // 2. Individual pots (Pot Scale)
    for (int i = 0; i < accountMap.length; i++) {
      if (i + 3 < showList.length && showList[i + 3] && accountMap[i].isNotEmpty && ageList.length >= accountMap[i].length) {
        name.add(nameList[i]);
        line.add(LineChartBarData(
          spots: accountMap[i].asMap().entries.map((e) => FlSpot(ageList[e.key], e.value)).toList(),
          isCurved: true,
          color: Colors.primaries[i % Colors.primaries.length].withOpacity(0.5),
          barWidth: 2,
          dotData: FlDotData(show: false),
        ));
      }
    }

    // 3. Sum Pot (Pot Scale)
    if (showList[0] && sumList.isNotEmpty && ageList.length >= sumList.length) {
      name.add('Sum');
      line.add(LineChartBarData(
        spots: sumList.asMap().entries.map((e) => FlSpot(ageList[e.key], e.value)).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        dotData: FlDotData(show: false),
      ));
    }

    // 4. Income / Outgoing (Visual: Normalized to Pot Scale)
    if (showList[1]) {
        if (incomeList.isNotEmpty && ageList.length >= incomeList.length) {
          name.add('Income');
          line.add(LineChartBarData(
            spots: incomeList.asMap().entries
                .map((e) => FlSpot(ageList[e.key], e.value * factor))
                .toList(),
            isCurved: true,
            color: Colors.green, // Positive
            barWidth: 2,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ));
        }
        
        if (outgoingList.isNotEmpty && ageList.length >= outgoingList.length) {
          name.add('Outgoing');
          line.add(LineChartBarData(
            spots: outgoingList.asMap().entries
                .map((e) => FlSpot(ageList[e.key], e.value * factor)) // Should be positive numbers representing outflow? Or negative?
                // Assuming provider returns positive numbers for "Amount Out", we plot them positively on Income axis?
                // Or maybe negative? User might prefer comparison. Usually cash flow charts show In vs Out both positive y-axis.
                // Let's assume positive magnitude. If they are negative in list, abs() them?
                // The Simulate logic: stepTotalOutgoing += t.amount. So they are positive magnitudes.
                .toList(),
            isCurved: true,
            color: Colors.red, // Negative
            barWidth: 2,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ));
        }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height * 0.7,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          lineBarsData: line,
          minY: pensionMin, // Base Scale Min
          maxY: pensionMax, // Base Scale Max
          minX: ageMin,
          maxX: ageMax,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (ageMax - ageMin) / 10,
                getTitlesWidget: (value, meta) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${value.toStringAsFixed(0)}'), // Age
                    Text('${addFractionalYear(dob, value).year}'), // Year below
                  ],
                ),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text("Pension (£)", style: TextStyle(color: Colors.blue)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: pensionMax / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value), 
                    style: const TextStyle(color: Colors.blue, fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: const Text("Account (£)", style: TextStyle(color: Colors.orange)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: pensionMax / 5, // Use same visual interval steps
                getTitlesWidget: (value, meta) {
                  // Denormalize: Label = Value / Factor
                  final realIncome = value / factor;
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
            horizontalInterval: pensionMax / 10,
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.grey.shade200, // Light grey background
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  bool isIncomeLine = spot.bar.dashArray != null;
                  
                  int index = spot.barIndex;
                  // The logic relying on 'name' index matches line order.
                  // Since cloud lines don't populate 'name', index offset is tricky!
                  // Cloud lines are added first.
                  
                  int cloudCount = cloudPaths.isNotEmpty && showList.length > 2 && showList[2] ? cloudPaths.length : 0;
                  
                  if (index < cloudCount) {
                     return null; // Don't show tooltip for cloud lines
                  }
                  
                  int realIndex = index - cloudCount;
                  if (realIndex < 0 || realIndex >= name.length) return null;

                  double value = spot.y;
                  String label = name[realIndex];
                  Color color = spot.bar.color ?? Colors.blue;

                  if (isIncomeLine) {
                    value = spot.y / factor; // Denormalize
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
