import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class StatePensionScreen extends StatefulWidget {
  const StatePensionScreen({super.key});

  @override
  State<StatePensionScreen> createState() =>
      _StatePensionScreenState();
}

class _StatePensionScreenState extends State<StatePensionScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController interestController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false)
        .fetchStatePension();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final sp = provider.statePension;

    if (sp.isNotEmpty) {
      ageController.text = sp['start_age'].toString();
      amountController.text = sp['amount'].toString();
      interestController.text =
          (sp['interest_rate'] * 100).toString();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('State Pension',
              style: TextStyle(fontSize: 24)),
          TextField(
            controller: ageController,
            decoration:
                const InputDecoration(labelText: 'Start Age'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            decoration:
                const InputDecoration(labelText: 'Amount (£)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: interestController,
            decoration: const InputDecoration(
                labelText: 'Interest Rate (%)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final age =
                  int.tryParse(ageController.text);
              final amount =
                  double.tryParse(amountController.text);
              final rate =
                  double.tryParse(interestController.text);

              if (age == null || amount == null || rate == null) return;

              provider.setStatePension({
                'start_age': age,
                'amount': amount,
                'interest_rate': rate / 100,
              });
            },
            child: const Text('Save State Pension'),
          ),
        ],
      ),
    );
  }
}
