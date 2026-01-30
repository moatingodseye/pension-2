import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/outgoing_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/screen_layout.dart';
import '../widgets/data_table_view.dart';
import '../widgets/forms/outgoing_form_dialog.dart';
import '../widgets/pagination_controls.dart';
import 'package:shared/models/outgoing.dart';

class OutgoingScreen extends StatefulWidget {
  const OutgoingScreen({super.key});

  @override
  State<OutgoingScreen> createState() => _OutgoingScreenState();
}

class _OutgoingScreenState extends State<OutgoingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OutgoingProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load(); 
    });
  }

  String _getAccountName(BuildContext context, int? id) {
    if (id == null) return 'General Pot';
    try {
       final account = Provider.of<AccountProvider>(context, listen: false).accounts.firstWhere((a) => a.id == id);
       return account.name;
    } catch (e) {
      return 'Unknown ($id)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OutgoingProvider>(
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
                     Text('Outgoings', style: Theme.of(context).textTheme.headlineSmall),
                     ElevatedButton.icon(
                       icon: const Icon(Icons.add),
                       label: const Text('Add Outgoing'),
                       onPressed: () => showDialog(context: context, builder: (_) => const OutgoingFormDialog()),
                     ),
                   ],
                 ),
               ),
               Expanded(
                 child: provider.isLoading && provider.outgoings.isEmpty
                 ? const Center(child: CircularProgressIndicator())
                 : DataTableView(
                   headers: const ['Name', 'Amount', 'Source', 'Start', 'End', 'Rate', 'Actions'],
                   columnAlignments: const [
                      MainAxisAlignment.start, 
                      MainAxisAlignment.end, 
                      MainAxisAlignment.start,
                      MainAxisAlignment.start,
                      MainAxisAlignment.start,
                      MainAxisAlignment.end,
                      MainAxisAlignment.end
                   ],
                   rows: provider.outgoings.map((out) {
                     return [
                       Text(out.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                       Text('£${out.amount.toStringAsFixed(2)}/mo', style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(_getAccountName(context, out.fromId), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                       Text(out.startAt.toString(), style: const TextStyle(fontSize: 13)),
                       Text(out.endAt?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
                       Text('${(out.rate * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                             onPressed: () => showDialog(context: context, builder: (_) => OutgoingFormDialog(outgoing: out)),
                             tooltip: 'Edit',
                           ),
                           IconButton(
                             icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                             onPressed: () => _confirmDelete(provider, out),
                             tooltip: 'Delete',
                           ),
                         ],
                       )
                     ];
                   }).toList(),
                   onAdd: () => showDialog(context: context, builder: (_) => const OutgoingFormDialog()),
                   addLabel: 'Add First Outgoing',
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

  void _confirmDelete(OutgoingProvider provider, Outgoing item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Outgoing?'),
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
