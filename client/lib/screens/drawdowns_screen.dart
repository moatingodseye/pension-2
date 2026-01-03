import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class DrawdownsScreen extends StatefulWidget {
  const DrawdownsScreen({super.key});

  @override
  State<DrawdownsScreen> createState() => _DrawdownsScreenState();
}

class _DrawdownsScreenState extends State<DrawdownsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController interestController = TextEditingController();

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  int? selectedPensionPotId;
  int? currentDrawdownId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchDrawdowns();
      Provider.of<DataProvider>(context, listen: false).fetchPensionPots();
    });
  }

  void _openDrawdownDialog(Map<String, dynamic>? drawdown) {
    if (drawdown != null) {
      amountController.text = drawdown['amount'].toString();
      startDateController.text = drawdown['start_date'];
      endDateController.text = drawdown['end_date'] ?? '';
      interestController.text =
          (drawdown['interest_rate'] * 100.0).toString();

      selectedStartDate = DateTime.parse(drawdown['start_date']);
      selectedEndDate =
          drawdown['end_date'] != null ? DateTime.parse(drawdown['end_date']) : null;
      selectedPensionPotId = drawdown['pension_pot_id'];
      currentDrawdownId = drawdown['id'];
    } else {
      amountController.clear();
      startDateController.clear();
      endDateController.clear();
      interestController.clear();
      selectedStartDate = null;
      selectedEndDate = null;
      selectedPensionPotId = null;
      currentDrawdownId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(drawdown == null ? 'Add Drawdown' : 'Edit Drawdown'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedPensionPotId,
                  hint: const Text('Select Pension Pot'),
                  items: Provider.of<DataProvider>(context)
                      .pensionPots
                      .map((pot) => DropdownMenuItem<int>(
                            value: pot['id'],
                            child: Text(pot['name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedPensionPotId = value);
                  },
                  validator: (value) =>
                      value == null ? 'Select a pension pot' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (£)'),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(ctx, true),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select start date' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(ctx, false),
                ),
                const SizedBox(height: 8),

                /// 🔧 FIXED ROW
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedEndDate = null;
                          endDateController.clear();
                        });
                      },
                      child: const Text('Clear End Date'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: interestController,
                        decoration:
                            const InputDecoration(labelText: 'Interest Rate (%)'),
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter interest rate' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;

              final drawdownData = {
                'amount': double.tryParse(amountController.text),
                'start_date': selectedStartDate!.toIso8601String(),
                'end_date': selectedEndDate?.toIso8601String(),
                'interest_rate':
                    (double.tryParse(interestController.text) ?? 0) / 100.0,
                'pension_pot_id': selectedPensionPotId,
              };

              if (currentDrawdownId == null) {
                Provider.of<DataProvider>(context, listen: false)
                    .addDrawdown(drawdownData);
              } else {
                Provider.of<DataProvider>(context, listen: false)
                    .updateDrawdown(currentDrawdownId!, drawdownData);
              }

              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
          startDateController.text = picked.toIso8601String().split('T')[0];
        } else {
          selectedEndDate = picked;
          endDateController.text = picked.toIso8601String().split('T')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);

    if (provider.pensionPots.isEmpty || provider.drawdowns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Drawdowns', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.drawdowns.length,
              itemBuilder: (ctx, i) {
                final d = provider.drawdowns[i];
                final potName = provider.pensionPots
                    .firstWhere(
                      (pot) => pot['id'] == d['pension_pot_id'],
                      orElse: () => {'name': 'No Pension Pot'},
                    )['name'];

                return ListTile(
                  title: Text(potName),
                  subtitle: Text(
                    'Amount: £${d['amount']} | Start: ${d['start_date']} | End: ${d['end_date'] ?? 'Indefinite'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDrawdownDialog(d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => provider.deleteDrawdown(d['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => _openDrawdownDialog(null),
            child: const Text('Add Drawdown'),
          ),
        ],
      ),
    );
  }
}
