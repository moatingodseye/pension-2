import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/account_provider.dart';
import '../providers/income_provider.dart';
import '../providers/outgoing_provider.dart';
import '../providers/transfer_provider.dart';
import '../widgets/chart_widget.dart';
import '../widgets/screen_layout.dart';
import '../services/csv_service.dart'; // Assuming we'll use this or similar for export

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  // What-If Parameters
  double _volatility = 0.12;
  double _rateAdjustment = 0.0;

  // Axis Parameters
  double _sumPotMin = 0.0;
  double _sumPotMax = 2000000.0;
  double _incomeMin = 0.0;
  double _incomeMax = 50000.0;
  double _xAxisMin = 0.0;
  double _xAxisMax = 120.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSimulation();
    });
  }

  void _runSimulation() {
    final provider = Provider.of<SimulationProvider>(context, listen: false);
    final authFn = Provider.of<AuthProvider>(context, listen: false);
    final accFn = Provider.of<AccountProvider>(context, listen: false);
    final incFn = Provider.of<IncomeProvider>(context, listen: false);
    final outFn = Provider.of<OutgoingProvider>(context, listen: false);
    final trFn = Provider.of<TransferProvider>(context, listen: false);

    // Ensure we have a valid DOB
    if (authFn.dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User DOB missing for simulation')));
      return;
    }

    provider.run(
      volatility: _volatility,
      rateAdjustment: _rateAdjustment,
      accounts: accFn.accounts,
      incomes: incFn.incomes,
      outgoings: outFn.outgoings,
      transfers: trFn.transfers,
      dob: authFn.dob!,
    ).then((_) {
      if (mounted && provider.result != null) {
        setState(() {
          // Auto-set defaults from result if needed, or keep user overrides
          // For now, let's keep user overrides or init if zero?
          // Actually, let's just respect the result defaults if valid
          if (_sumPotMax == 2000000.0 && provider.result!.sumPotMax != 100) {
             _sumPotMin = provider.result!.sumPotMin;
             _sumPotMax = provider.result!.sumPotMax;
             _incomeMin = provider.result!.incomeMin;
             _incomeMax = provider.result!.incomeMax;
             _xAxisMin = provider.result!.xAxisMin;
             _xAxisMax = provider.result!.xAxisMax;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SimulationProvider>(context);
    final result = provider.result;

    Widget content;
    if (provider.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null) {
      content = Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
    } else if (result == null) {
      content = const Center(child: Text('No simulation data.'));
    } else {
      content = Padding(
        padding: const EdgeInsets.all(16.0),
        child: SimulationChart(
          sumPot: result.sum,
          income: result.income,
          pots: result.pots,
          mcMin: result.monteMin,
          mcMax: result.monteMax,
          ages: result.ages,
          showLines: provider.showLines,
          sumPotMin: _sumPotMin,
          sumPotMax: _sumPotMax,
          incomeMin: _incomeMin,
          incomeMax: _incomeMax,
          xAxisMin: _xAxisMin,
          xAxisMax: _xAxisMax,
          // matched refactored widget signature
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Simulation')),
      // Use ScreenLayout with body and sidebar
      body: ScreenLayout(
        body: content,
        sidebar: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Controls', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              // 1. What-If Analysis
              ExpansionTile(
                title: const Text('What-If Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: [
                   const Text('Volatility (Risk)'),
                   Slider(
                     value: _volatility,
                     min: 0.0,
                     max: 0.5,
                     divisions: 50,
                     label: '${(_volatility * 100).toStringAsFixed(1)}%',
                     onChanged: (v) => setState(() => _volatility = v),
                   ),
                   Text('Value: ${(_volatility * 100).toStringAsFixed(1)}%'),
                   const SizedBox(height: 10),
                   
                   const Text('Growth Adjustment'),
                   Slider(
                     value: _rateAdjustment,
                     min: -0.05,
                     max: 0.05,
                     divisions: 20,
                     label: '${(_rateAdjustment * 100).toStringAsFixed(1)}%',
                     onChanged: (v) => setState(() => _rateAdjustment = v),
                   ),
                   Text('Value: ${(_rateAdjustment * 100).toStringAsFixed(1)}%'),
                   
                   const SizedBox(height: 10),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton.icon(
                       icon: const Icon(Icons.play_arrow),
                       label: const Text('Run Simulation'),
                       onPressed: _runSimulation,
                     ),
                   ),
                ],
              ),
              
              const Divider(),
              
              // 2. Chart Options
              ExpansionTile(
                title: const Text('Chart Options', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  // Toggles
                  if (result != null) ...[
                     Wrap(
                        spacing: 8,
                        children: [
                           FilterChip(
                             label: const Text('Sum'),
                             selected: provider.showLines[0],
                             onSelected: (v) => provider.toggleLine(0),
                           ),
                           FilterChip(
                             label: const Text('Income'),
                             selected: provider.showLines[1],
                             onSelected: (v) => provider.toggleLine(1),
                           ),
                           FilterChip(
                             label: const Text('Monte Carlo'),
                             selected: provider.showLines[2],
                             onSelected: (v) => provider.toggleLine(2),
                           ),
                           ...List.generate(result.pots.length, (i) {
                             return FilterChip(
                               label: Text('Pot ${i+1}'),
                               selected: i+3 < provider.showLines.length ? provider.showLines[i+3] : false,
                               onSelected: (v) => provider.toggleLine(i+3),
                             );
                           }),
                        ],
                     ),
                  ],
                  const SizedBox(height: 10),
                  // Axis Config
                  const Text('Axis Limits', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildAxisInput('Pot Max', _sumPotMax, (v) => setState(() => _sumPotMax = v)),
                  _buildAxisInput('Income Max', _incomeMax, (v) => setState(() => _incomeMax = v)),
                  _buildAxisInput('Age Max', _xAxisMax, (v) => setState(() => _xAxisMax = v)),
                ],
              ),
              
              const Divider(),
              
              // 3. Export
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Results (CSV)'),
                  onPressed: () {
                     // Implement simple export or use CsvService
                     if (result != null) {
                       final csv = CsvService.exportSimulation(result); // Need to add this method to CsvService
                       CsvService.copyToClipboard(context, csv);
                     }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAxisInput(String label, double val, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: val.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(8),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }
}
