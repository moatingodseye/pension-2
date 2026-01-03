import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'axisInputScreen.dart';
import '../providers/data_provider.dart';
import '../widgets/chart_widget.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late DataProvider dp;

  // Default axis min/max values
  double sumPotMin = 0.0;
  double sumPotMax = 2000000.0;
  double incomeMin = 0.0;
  double incomeMax = 50000.0;
  double xAxisMin = 0.0;
  double xAxisMax = 120.0;

  @override
  void initState() {
    super.initState();
    dp = Provider.of<DataProvider>(context, listen: false);
    dp.simulate().then((_) {
      setState(() {
        sumPotMin = dp.simulationResults['sumMin'] ?? 0.0;
        sumPotMax = dp.simulationResults['sumMax'] ?? 2000000.0;
        incomeMin = dp.simulationResults['incomeMin'] ?? 0.0;
        incomeMax = dp.simulationResults['incomeMax'] ?? 50000.0;
        xAxisMin = dp.simulationResults['xAxisMin'] ?? 0.0;
        xAxisMax = dp.simulationResults['xAxisMax'] ?? 120.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DataProvider>(context);
    if (dp.simulationResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<bool> showLines = dp.showLines;

    // Properly cast all data from dynamic to strongly typed
    final sum = List<double>.from(dp.simulationResults['sum']!);
    final income = List<double>.from(dp.simulationResults['income']!);
    final pots = (dp.simulationResults['pots']! as List)
        .map((p) => List<double>.from(p))
        .toList();
    final monteMin = List<double>.from(dp.simulationResults['monte_min']!);
    final monteMax = List<double>.from(dp.simulationResults['monte_max']!);
    final ages = List<double>.from(dp.simulationResults['ages']!);

    return DefaultTabController(
      length: 2,  // Two tabs: One for Pension, another for Income
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Simulation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pension'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: Column(
          children: [
            // TabBarView to switch between charts
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Pension chart
                  SimulationChart(
                    sumPot: sum,
                    income: income,
                    pots: pots,
                    mcMin: monteMin,
                    mcMax: monteMax,
                    ages: ages,
                    showLines: showLines,
                    sumPotMin: sumPotMin,
                    sumPotMax: sumPotMax,
                    incomeMin: incomeMin,
                    incomeMax: incomeMax,
                    xAxisMin: xAxisMin,
                    xAxisMax: xAxisMax,
                    isIncomeChart: false,  // Pension chart
                  ),
                  // Tab 2: Income chart
                  SimulationChart(
                    sumPot: sum,
                    income: income,
                    pots: pots,
                    mcMin: monteMin,
                    mcMax: monteMax,
                    ages: ages,
                    showLines: showLines,
                    sumPotMin: sumPotMin,
                    sumPotMax: sumPotMax,
                    incomeMin: incomeMin,
                    incomeMax: incomeMax,
                    xAxisMin: xAxisMin,
                    xAxisMax: xAxisMax,
                    isIncomeChart: true,  // Income chart
                  ),
                ],
              ),
            ),
            // Show lines toggles
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Sum of Pots'),
                    selected: showLines[0],
                    onSelected: (v) {
                      setState(() => showLines[0] = v);
                    },
                  ),
                  FilterChip(
                    label: const Text('Income'),
                    selected: showLines[1],
                    onSelected: (v) {
                      setState(() => showLines[1] = v);
                    },
                  ),
                  FilterChip(
                    label: const Text('Monte Carlo'),
                    selected: showLines[2],
                    onSelected: (v) {
                      setState(() => showLines[2] = v);
                    },
                  ),
                  ...List.generate(pots.length, (i) {
                    return FilterChip(
                      label: Text('Pot ${i + 1}'),
                      selected: showLines[i + 3],
                      onSelected: (v) {
                        setState(() => showLines[i + 3] = v);
                      },
                    );
                  }),
                ],
              ),
            ),
            // Edit Axis Button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  // Open the AxisInputScreen as a dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AxisInputScreen(
                        sumPotMin: sumPotMin,
                        sumPotMax: sumPotMax,
                        incomeMin: incomeMin,
                        incomeMax: incomeMax,
                        xAxisMin: xAxisMin,
                        xAxisMax: xAxisMax,
                        onSave: (newValues) {
                          setState(() {
                            sumPotMin = newValues['sumPotMin']!;
                            sumPotMax = newValues['sumPotMax']!;
                            incomeMin = newValues['incomeMin']!;
                            incomeMax = newValues['incomeMax']!;
                            xAxisMin = newValues['xAxisMin']!;
                            xAxisMax = newValues['xAxisMax']!;
                          });
                        },
                      );
                    },
                  );
                },
                child: const Text('Edit Axis Values'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
