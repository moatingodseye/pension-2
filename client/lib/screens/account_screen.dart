import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../widgets/screen_layout.dart';
import '../widgets/data_table_view.dart';
import '../widgets/forms/account_form_dialog.dart';
import '../widgets/pagination_controls.dart';
import 'package:shared/models/account.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading && provider.accounts.isEmpty) {
           return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
        }

        return ScreenLayout(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Accounts', style: Theme.of(context).textTheme.headlineSmall),
                     ElevatedButton.icon(
                       icon: const Icon(Icons.add),
                       label: const Text('Add Account'),
                       onPressed: () => showDialog(context: context, builder: (_) => const AccountFormDialog()),
                     ),
                   ],
                 ),
               ),
               Expanded(
                 child: DataTableView(
                   headers: const ['Type', 'Name', 'Balance', 'Date', 'Interest', 'Actions'],
                   columnAlignments: const [
                      MainAxisAlignment.start, 
                      MainAxisAlignment.start, 
                      MainAxisAlignment.end, 
                      MainAxisAlignment.end,
                      MainAxisAlignment.end,
                      MainAxisAlignment.end
                   ],
                   rows: provider.accounts.map((acc) {
                     return [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: acc.type.label == 'Pension' ? Colors.purple.shade50 : Colors.green.shade50,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: acc.type.label == 'Pension' ? Colors.purple.shade200 : Colors.green.shade200),
                         ),
                         child: Text(acc.type.label, style: TextStyle(fontSize: 12, color: acc.type.label == 'Pension' ? Colors.purple : Colors.green)),
                       ),
                       Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                       Text('£${acc.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text(acc.amountAt.toString().split('T')[0], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                       Text('${(acc.rate * 100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                             onPressed: () => showDialog(context: context, builder: (_) => AccountFormDialog(account: acc)),
                             tooltip: 'Edit',
                           ),
                           IconButton(
                             icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                             onPressed: () => _confirmDelete(provider, acc),
                             tooltip: 'Delete',
                           ),
                         ],
                       )
                     ];
                   }).toList(),
                   onAdd: () => showDialog(context: context, builder: (_) => const AccountFormDialog()),
                   addLabel: 'Add First Account',
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
          // No sidebar needed for forms anymore as they are dialogs
        );
      },
    );
  }

  void _confirmDelete(AccountProvider provider, Account acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to delete "${acc.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.delete(acc.id!);
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
