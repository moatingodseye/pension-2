import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'axisInputScreen.dart';
import '../providers/simulation_provider.dart';
import '../widgets/chart_widget.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  // Axis values state, initially null or defaults, updated by Provider result or AxisInputScreen
  double? sumPotMin;
  double? sumPotMax;
  double? incomeMin;
  double? incomeMax;
  double? xAxisMin;
  double? xAxisMax;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final prov = Provider.of<SimulationProvider>(context, listen: false);
       prov.run().then((_) {
         if (mounted && prov.result != null) {
           setState(() {
              sumPotMin = prov.result!.sumPotMin;
              sumPotMax = prov.result!.sumPotMax;
              incomeMin = prov.result!.incomeMin;
              incomeMax = prov.result!.incomeMax;
              xAxisMin = prov.result!.xAxisMin;
              xAxisMax = prov.result!.xAxisMax;
           });
         }
       });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SimulationProvider>(context);
    final result = provider.result;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.error != null) {
        return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
    }

    if (result == null) {
        return const Center(child: Text('No simulation data.'));
    }

    List<bool> showLines = provider.showLines;
    
    // Fallback defaults if null
    final curSumMin = sumPotMin ?? result.sumPotMin;
    final curSumMax = sumPotMax ?? result.sumPotMax;
    final curIncMin = incomeMin ?? result.incomeMin;
    final curIncMax = incomeMax ?? result.incomeMax;
    final curXMin = xAxisMin ?? result.xAxisMin;
    final curXMax = xAxisMax ?? result.xAxisMax;

    return DefaultTabController(
      length: 2,
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
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Pension chart
                  SimulationChart(
                    sumPot: result.sum,
                    income: result.income,
                    pots: result.pots,
                    mcMin: result.monteMin,
                    mcMax: result.monteMax,
                    ages: result.ages,
                    showLines: showLines,
                    sumPotMin: curSumMin,
                    sumPotMax: curSumMax,
                    incomeMin: curIncMin,
                    incomeMax: curIncMax,
                    xAxisMin: curXMin,
                    xAxisMax: curXMax,
                    isIncomeChart: false,
                  ),
                  // Tab 2: Income chart
                  SimulationChart(
                    sumPot: result.sum,
                    income: result.income,
                    pots: result.pots,
                    mcMin: result.monteMin,
                    mcMax: result.monteMax,
                    ages: result.ages,
                    showLines: showLines,
                    sumPotMin: curSumMin,
                    sumPotMax: curSumMax,
                    incomeMin: curIncMin,
                    incomeMax: curIncMax,
                    xAxisMin: curXMin,
                    xAxisMax: curXMax,
                    isIncomeChart: true,
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
                    onSelected: (v) => provider.toggleLine(0),
                  ),
                  FilterChip(
                    label: const Text('Income'),
                    selected: showLines[1],
                    onSelected: (v) => provider.toggleLine(1),
                  ),
                  FilterChip(
                    label: const Text('Monte Carlo'),
                    selected: showLines[2],
                    onSelected: (v) => provider.toggleLine(2),
                  ),
                  ...List.generate(result.pots.length, (i) {
                    return FilterChip(
                      label: Text('Pot ${i + 1}'),
                      selected: i + 3 < showLines.length ? showLines[i + 3] : false, // Safety check
                      onSelected: (v) => provider.toggleLine(i + 3),
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AxisInputScreen(
                        sumPotMin: curSumMin,
                        sumPotMax: curSumMax,
                        incomeMin: curIncMin,
                        incomeMax: curIncMax,
                        xAxisMin: curXMin,
                        xAxisMax: curXMax,
                        onSave: (newValues) {
                          setState(() {
                            sumPotMin = newValues['sumPotMin'];
                            sumPotMax = newValues['sumPotMax'];
                            incomeMin = newValues['incomeMin'];
                            incomeMax = newValues['incomeMax'];
                            xAxisMin = newValues['xAxisMin'];
                            xAxisMax = newValues['xAxisMax'];
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
