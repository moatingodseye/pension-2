import 'package:flutter/material.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dataset, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Data Management', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Use the secondary sidebar for Import/Export actions.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Supported Import Formats: CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                   SizedBox(height: 8),
                  Text('Ensure columns match the export format.'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
