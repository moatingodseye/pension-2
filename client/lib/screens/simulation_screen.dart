import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simulationProvider.dart';
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
  // Duration Parameters
  int _durationMode = 0; // 0=MaxAge(120), 1=EndAge, 2=FixedDuration
  bool _byMonth = false;
  double _targetEndAge = 70.0;
  double _targetDuration = 20.0;
  
  // What-If Parameters
  double _volatility = 0.12;
  double _rateAdjustment = 0.0;

  // Axis Parameters
  bool _initialised = false;
  double _ageMin = 0.0; // x-axis
  double _ageMax = 120.0;
  double _pensionMin = 0.0; // left y-axis
  double _pensionMax = 2000000.0;
  double _accountMin = 0.0;
  double _accountMax = 50000.0; // right y-axis
  DateTime dob = DateTime(1900,1,1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSimulation();
    });
  }

  void _runSimulation() async {
    final provider = Provider.of<SimulationProvider>(context, listen: false);
    final authFn = Provider.of<AuthProvider>(context, listen: false);
    final accFn = Provider.of<AccountProvider>(context, listen: false);
    final incFn = Provider.of<IncomeProvider>(context, listen: false);
    final outFn = Provider.of<OutgoingProvider>(context, listen: false);
    final trFn = Provider.of<TransferProvider>(context, listen: false);

    await accFn.load();
    await incFn.load();
    await outFn.load();
    await trFn.load();

    // Ensure we have a valid DOB
    if (authFn.user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User missing for simulation')));
      return;
    }

    dob = authFn.user!.dob!;

    int? endAgeParam;
    int? durationParam;
    
    if (_durationMode == 1) endAgeParam = _targetEndAge.toInt();
    if (_durationMode == 2) durationParam = _targetDuration.toInt();

    provider.run(
      volatility: _volatility,
      rateAdjustment: _rateAdjustment,
      byMonth: _byMonth,
      endAge: endAgeParam,
      durationYear: durationParam,
      accountList: accFn.accounts,
      incomeList: incFn.incomes,
      outgoingList: outFn.outgoings,
      transferList: trFn.transfers,
      user: authFn.user!,
    ).then((_) {
      if (mounted && provider.result != null) {
        setState(() {
          // Keep user defaults unless force reset logic needed
          // Auto-set defaults from result if needed, or keep user overrides
          // For now, let's keep user overrides or init if zero?
          // Actually, let's just respect the result defaults if valid
          if (_initialised && provider.result!=null) {
             _pensionMin = provider.result!.pensionMin;
             _pensionMax = provider.result!.pensionMax;
             _accountMin = provider.result!.accountMin;
             _accountMax = provider.result!.accountMax;
             _ageMin = provider.result!.ageMin;
             _ageMax = provider.result!.ageMax;
             _initialised = true;
          }        });
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
          ageMin: result.ageMin,
          ageMax: result.ageMax,
          nameList: result.nameList,
          sumList: result.sumList,
          incomeList: result.incomeList,
          outgoingList: result.outgoingList,
          accountMap: result.accountMap,
          mcMinList: result.monteMinList,
          mcMaxList: result.monteMaxList,
          ageList: result.ageList,
          showList: result.nameList.map((name) => provider.showList[name] ?? true).toList(),
          pensionMin: result.pensionMin,
          pensionMax: result.pensionMax,
          accountMin: result.accountMin,
          accountMax: result.accountMax,
          dob: dob,
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
                   
                   const Divider(),
                   
                   const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
                   DropdownButton<int>(
                     value: _byMonth==true ? 1 : 12,
                     isExpanded: true,
                     items: const [
                       DropdownMenuItem(value: 12, child: Text('Yearly')),
                       DropdownMenuItem(value: 1, child: Text('Monthly')),
                     ],
                     onChanged: (v) {
                       if (v != null) setState(() => v==1 ? _byMonth = true : _byMonth = false);
                     },
                   ),
                   const SizedBox(height: 10),

                   const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold)),
                   SegmentedButton<int>(
                     segments: const [
                       ButtonSegment(value: 0, label: Text('Max')),
                       ButtonSegment(value: 1, label: Text('Age')),
                       ButtonSegment(value: 2, label: Text('Years')),
                     ],
                     selected: {_durationMode},
                     onSelectionChanged: (Set<int> newSelection) {
                       setState(() {
                         _durationMode = newSelection.first;
                       });
                     },
                   ),
                   if (_durationMode == 1) ...[
                      const SizedBox(height: 5),
                      Text('End Age: ${_targetEndAge.toInt()}'),
                      Slider(
                        value: _targetEndAge,
                        min: 18,
                        max: 120,
                        divisions: 102,
                        label: '${_targetEndAge.toInt()}',
                        onChanged: (v) => setState(() => _targetEndAge = v),
                      ),
                   ],
                   if (_durationMode == 2) ...[
                      const SizedBox(height: 5),
                      Text('Duration: ${_targetDuration.toInt()} Years'),
                      Slider(
                        value: _targetDuration,
                        min: 5,
                        max: 100,
                        divisions: 95,
                        label: '${_targetDuration.toInt()}',
                        onChanged: (v) => setState(() => _targetDuration = v),
                      ),
                   ],

                   const SizedBox(height: 16),
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
                             selected: provider.showList['Sum'] ?? true,
                             onSelected: (v) => provider.toggleLine('Sum'),
                           ),
                           FilterChip(
                             label: const Text('Income'),
                             selected: provider.showList['Income'] ?? true,
                             onSelected: (v) => provider.toggleLine('Income'),
                           ),
                           FilterChip(
                             label: const Text('Monte Carlo'),
                             selected: provider.showList['Monte Carlo'] ?? true,
                             onSelected: (v) => provider.toggleLine('Monte Carlo'),
                           ),
                           ...result.nameList.map((name) {
                             return FilterChip(
                               label: Text(name),
                               selected: provider.showList[name] ?? true,
                               onSelected: (v) => provider.toggleLine(name),
                             );
                           }),
                        ],
                     ),
                  ],
                  const SizedBox(height: 10),
                  // Axis Config
                  const Text('Axis Limits', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildAxisInput('Pension Max', _pensionMax, (v) => setState(() => _pensionMax = v)),
                  _buildAxisInput('Account Max', _accountMax, (v) => setState(() => _accountMax = v)),
                  _buildAxisInput('Age Max', _ageMax, (v) => setState(() => _ageMax = v)),
                ],
              ),
              
              const Divider(),
              
              // 3. Export
              SizedBox(
                width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy CSV'),
                          onPressed: () {
                             if (result != null) {
                               final csv = CsvService.exportSimulation(result);
                               CsvService.copyToClipboard(context, csv);
                             }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Save CSV'),
                          onPressed: () async {
                             if (result != null) {
                               final csv = CsvService.exportSimulation(result);
                               await CsvService.saveAndExport(context, csv, 'simulation_pension_export.csv');
                             }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ]
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
