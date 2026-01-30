import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/income_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/screen_layout.dart';
import '../widgets/data_table_view.dart';
import '../widgets/forms/income_form_dialog.dart';
import '../widgets/pagination_controls.dart';
import 'package:shared/models/income.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncomeProvider>(context, listen: false).load();
      // Ensure accounts are loaded for the lookups if needed, though provider usually handles logic
      Provider.of<AccountProvider>(context, listen: false).load(); 
    });
  }

  String _getAccountName(BuildContext context, int? id) {
    if (id == null) return 'General Pot';
    final acc = Provider.of<AccountProvider>(context, listen: false).accounts
        .firstWhere((a) => a.id == id, orElse: () => throw Exception('Account not found')); // Handle gracefully in real app
    // Actually safer to just find or return Unknown
    try {
       final account = Provider.of<AccountProvider>(context, listen: false).accounts.firstWhere((a) => a.id == id);
       return account.name;
    } catch (e) {
      return 'Unknown ($id)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeProvider>(
      builder: (ctx, provider, _) {
       
        return ScreenLayout(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Incomes', style: Theme.of(context).textTheme.headlineSmall),
                     ElevatedButton.icon(
                       icon: const Icon(Icons.add),
                       label: const Text('Add Income'),
                       onPressed: () => showDialog(context: context, builder: (_) => const IncomeFormDialog()),
                     ),
                   ],
                 ),
               ),
               Expanded(
                 child: provider.isLoading && provider.incomes.isEmpty
                 ? const Center(child: CircularProgressIndicator())
                 : DataTableView(
                   headers: const ['Name', 'Amount', 'Destination', 'Start', 'End', 'Rate', 'Actions'],
                   columnAlignments: const [
                      MainAxisAlignment.start, 
                      MainAxisAlignment.end, 
                      MainAxisAlignment.start,
                      MainAxisAlignment.start,
                      MainAxisAlignment.start,
                      MainAxisAlignment.end,
                      MainAxisAlignment.end
                   ],
                   rows: provider.incomes.map((inc) {
                     return [
                       Text(inc.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                       Text('£${inc.amount.toStringAsFixed(2)}/mo', style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(_getAccountName(context, inc.intoId), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                       Text(inc.startAt.toString(), style: const TextStyle(fontSize: 13)),
                       Text(inc.endAt?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
                       Text('${(inc.rate * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                             onPressed: () => showDialog(context: context, builder: (_) => IncomeFormDialog(income: inc)),
                             tooltip: 'Edit',
                           ),
                           IconButton(
                             icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                             onPressed: () => _confirmDelete(provider, inc),
                             tooltip: 'Delete',
                           ),
                         ],
                       )
                     ];
                   }).toList(),
                   onAdd: () => showDialog(context: context, builder: (_) => const IncomeFormDialog()),
                   addLabel: 'Add First Income',
                 ),
               ),
               PaginationControls(
                 page: provider.page,
                 totalCount: provider.totalCount,
                 limit: provider.limit,
                 onPageChanged: provider.setPage,
                 isLoading: provider.isLoading,
               ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(IncomeProvider provider, Income item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.delete(item.id!);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
