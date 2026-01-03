import 'package:flutter/material.dart';

class AxisInputScreen extends StatefulWidget {
  final double sumPotMin;
  final double sumPotMax;
  final double incomeMin;
  final double incomeMax;
  final double xAxisMin;
  final double xAxisMax;
  final Function(Map<String, double>) onSave;

  const AxisInputScreen({super.key, 
    required this.sumPotMin,
    required this.sumPotMax,
    required this.incomeMin,
    required this.incomeMax,
    required this.xAxisMin,
    required this.xAxisMax,
    required this.onSave,
  });

  @override
  State<AxisInputScreen> createState() => _AxisInputScreenState();
}

class _AxisInputScreenState extends State<AxisInputScreen> {
  late TextEditingController sumPotMinController;
  late TextEditingController sumPotMaxController;
  late TextEditingController incomeMinController;
  late TextEditingController incomeMaxController;
  late TextEditingController xAxisMinController;
  late TextEditingController xAxisMaxController;

  @override
  void initState() {
    super.initState();

    // Initialize the controllers with the current values passed from SimulationScreen
    sumPotMinController = TextEditingController(text: widget.sumPotMin.toStringAsFixed(0));
    sumPotMaxController = TextEditingController(text: widget.sumPotMax.toStringAsFixed(0));
    incomeMinController = TextEditingController(text: widget.incomeMin.toStringAsFixed(0));
    incomeMaxController = TextEditingController(text: widget.incomeMax.toStringAsFixed(0));
    xAxisMinController = TextEditingController(text: widget.xAxisMin.toStringAsFixed(0));
    xAxisMaxController = TextEditingController(text: widget.xAxisMax.toStringAsFixed(0));
  }

  @override
  void dispose() {
    // Dispose the controllers when done
    sumPotMinController.dispose();
    sumPotMaxController.dispose();
    incomeMinController.dispose();
    incomeMaxController.dispose();
    xAxisMinController.dispose();
    xAxisMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Axis Values')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: sumPotMinController,
              decoration: const InputDecoration(labelText: 'Sum Pot Min'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sumPotMaxController,
              decoration: const InputDecoration(labelText: 'Sum Pot Max'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: incomeMinController,
              decoration: const InputDecoration(labelText: 'Income Min'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: incomeMaxController,
              decoration: const InputDecoration(labelText: 'Income Max'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: xAxisMinController,
              decoration: const InputDecoration(labelText: 'X Axis Min'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: xAxisMaxController,
              decoration: const InputDecoration(labelText: 'X Axis Max'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Collect new values and pass them back to the parent screen
                widget.onSave({
                  'sumPotMin': double.tryParse(sumPotMinController.text) ?? widget.sumPotMin,
                  'sumPotMax': double.tryParse(sumPotMaxController.text) ?? widget.sumPotMax,
                  'incomeMin': double.tryParse(incomeMinController.text) ?? widget.incomeMin,
                  'incomeMax': double.tryParse(incomeMaxController.text) ?? widget.incomeMax,
                  'xAxisMin': double.tryParse(xAxisMinController.text) ?? widget.xAxisMin,
                  'xAxisMax': double.tryParse(xAxisMaxController.text) ?? widget.xAxisMax,
                });
                Navigator.pop(context); // Close the input screen
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
