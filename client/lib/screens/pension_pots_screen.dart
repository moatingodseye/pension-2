import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class PensionPotsScreen extends StatefulWidget {
  const PensionPotsScreen({super.key});

  @override
  State<PensionPotsScreen> createState() => _PensionPotsScreenState();
}

class _PensionPotsScreenState extends State<PensionPotsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();

    // Fetch pension pots after the widget has finished building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchPensionPots();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in DataProvider
    return Consumer<DataProvider>(
      builder: (ctx, provider, _) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Pension Pots', style: TextStyle(fontSize: 24)),
            Expanded(
              child: ListView.builder(
                itemCount: provider.pensionPots.length,
                itemBuilder: (ctx, i) {
                  final pot = provider.pensionPots[i];
                  return ListTile(
                    title: Text(pot['name'] ?? 'No Name'), // Safely handle name null
                    subtitle: Text(
                        '£${pot['amount']} | Date: ${pot['date']} | Rate: ${pot['interest_rate']*100.0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editPensionPot(pot);
                          },
                        ),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              provider.deletePensionPot(pot['id'] as int),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    decoration:
                        const InputDecoration(labelText: 'Amount (£)'),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _pickDate(context),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Select date' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: interestController,
                    decoration: const InputDecoration(
                        labelText: 'Interest Rate (%)'),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter rate' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      final amount =
                          double.tryParse(amountController.text);
                      final rate = double.tryParse(interestController.text);
                      if (amount == null || rate == null || selectedDate == null) {
                        return;
                      }
                      provider.addPensionPot({
                        'name': nameController.text, // Include name
                        'amount': amount,
                        'date': selectedDate!.toIso8601String(),
                        'interest_rate': rate / 100.0,
                      });
                      amountController.clear();
                      dateController.clear();
                      interestController.clear();
                      nameController.clear();
                      selectedDate = null;
                    },
                    child: const Text('Add Pension Pot'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _editPensionPot(Map<String, dynamic> pot) {
    // Populate form with current data
    nameController.text = pot['name'] ?? '';
    amountController.text = pot['amount'].toString();
    dateController.text = pot['date'];
    interestController.text = (pot['interest_rate'] * 100.0).toString();

    // Show a dialog or navigate to an edit screen
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pension Pot'),
        content: Form(
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: amountController,
                decoration:
                    const InputDecoration(labelText: 'Amount (£)'),
              ),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
              ),
              TextFormField(
                controller: interestController,
                decoration:
                    const InputDecoration(labelText: 'Interest Rate'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedPot = {
                'name': nameController.text,
                'amount': double.tryParse(amountController.text),
                'date': dateController.text,
                'interest_rate': (double.tryParse(interestController.text) ?? 0.0)/100.0,
              };

              // Call the update API
              Provider.of<DataProvider>(context, listen: false).updatePensionPot(
                  pot['id'], updatedPot); // Pass ID and updated pot data

              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
