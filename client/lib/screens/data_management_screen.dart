import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../services/csv_service.dart';
import '../providers/account_provider.dart';
import '../providers/income_provider.dart';
import '../providers/outgoing_provider.dart';
import '../providers/transfer_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/screen_layout.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  Future<void> _exportData(BuildContext context, bool useFile) async {
    final csvService = CsvService();
    final accProv = Provider.of<AccountProvider>(context, listen: false);
    final incProv = Provider.of<IncomeProvider>(context, listen: false);
    final outProv = Provider.of<OutgoingProvider>(context, listen: false);
    final transProv = Provider.of<TransferProvider>(context, listen: false);

    // Ensure data is loaded
    await Future.wait([
      accProv.load(),
      incProv.load(),
      outProv.load(),
      transProv.load(),
    ]);

    final accountsCsv = csvService.exportAccounts(accProv.accounts);
    final incomesCsv = csvService.exportIncomes(incProv.incomes);
    final outgoingsCsv = csvService.exportOutgoings(outProv.outgoings);
    final transfersCsv = csvService.exportTransfers(transProv.transfers);

    // Simple robust format: We will export separate files or one single file?
    // User probably wants separate files or one big text dump.
    // For "Export All", let's export string dump.
    // For proper CSV backup, unrelated files usually better.
    // But let's stick to the previous 'dump' format for "All".
    
    final allData = '== ACCOUNTS ==\n$accountsCsv\n\n'
        '== INCOMES ==\n$incomesCsv\n\n'
        '== OUTGOINGS ==\n$outgoingsCsv\n\n'
        '== TRANSFERS ==\n$transfersCsv';

    if (useFile) {
      await CsvService.saveAndExport(context, allData, 'pension_data_backup.txt');
    } else {
      await CsvService.copyToClipboard(context, allData);
    }
  }

  Future<void> _importData(BuildContext context) async {
      // 1. Pick File
      final content = await CsvService.pickAndRead(context);
      if (content == null) return;
      
      // 2. Identify Type (Simple heuristic or ask user, but let's try to auto-detect header)
      final csvService = CsvService();
      
      // We will try parsing as each type.
      // Or we can support importing the "Export All" format if we parse sections.
      // Let's support individual CSVs first as that's standard.
      
      try {
          if (content.contains('== ACCOUNTS ==')) {
              // It's a dump file, sophisticated parsing needed. MVP: Only import individual CSVs.
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk dump import not supported yet. Import individual CSVs.')));
              return;
          }
          
          bool imported = false;
          
          // Accounts?
          if (content.contains('id,name,amount,type,date,rate') || (content.contains('name') && content.contains('amount') && content.contains('type'))) {
              final list = csvService.parseAccounts(content);
              if (list.isNotEmpty) {
                  final prov = Provider.of<AccountProvider>(context, listen: false);
                  for(var item in list) {
                    await prov.add(item);
                  }
                  imported = true;
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Accounts')));
              }
          } 
          // Incomes?
          else if (content.contains('intoAccount')) { // Unique enough?
              final list = csvService.parseIncomes(content);
              if (list.isNotEmpty) {
                  final prov = Provider.of<IncomeProvider>(context, listen: false);
                  for(var item in list) {
                    await prov.add(item);
                  }
                  imported = true;
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Incomes')));
              }
          }
          // Outgoings?
          else if (content.contains('fromAccount')) { // Unique enough?
              // Outgoing shares similar structure but 'fromAccount' vs 'intoAccount' (Income) vs 'fromAccount,intoAccount' (Transfer)
              // Transfer has 'intoAccount' AND 'fromAccount'.
              // Outgoing has 'fromAccount' only?
              
              if (content.contains('intoAccount')) {
                   // Must be transfer
                    final list = csvService.parseTransfers(content);
                    if (list.isNotEmpty) {
                        final prov = Provider.of<TransferProvider>(context, listen: false);
                        for(var item in list) {
                          await prov.add(item);
                        }
                        imported = true;
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Transfers')));
                    }
              } else {
                   // Outgoing
                    final list = csvService.parseOutgoings(content);
                    if (list.isNotEmpty) {
                        final prov = Provider.of<OutgoingProvider>(context, listen: false);
                        for(var item in list) {
                          await prov.add(item);
                        }
                        imported = true;
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${list.length} Outgoings')));
                    }
              }
          }
          
          if (!imported && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not identify CSV type or file empty.')));
          }

      } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
      }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dataset, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Data Management', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Use the sidebar for actions.'),
            const SizedBox(height: 20),
            const Text('Supported Import Formats: CSV', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Columns must match export format.'),
          ],
        ),
      ),
      sidebar: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text('Export', style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 12),
             ElevatedButton.icon(
               icon: const Icon(Icons.copy),
               label: const Text('Copy to Clipboard'),
               onPressed: () => _exportData(context, false),
             ),
             const SizedBox(height: 8),
             ElevatedButton.icon(
               icon: const Icon(Icons.save),
               label: const Text('Save to File'),
               onPressed: () => _exportData(context, true),
             ),
             
             const Divider(height: 32),
             Text('Import', style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 12),
             ElevatedButton.icon(
               icon: const Icon(Icons.upload_file),
               label: const Text('Import CSV File'),
               onPressed: () => _importData(context),
             ),
          ],
        ),
      ),
    );
  }
}
