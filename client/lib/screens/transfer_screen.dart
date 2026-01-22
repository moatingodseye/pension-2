import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/transfer.dart';
import '../widgets/currency_input.dart';
import '../widgets/age_or_date_input.dart';
import '../widgets/account_dropdown.dart';
import '../widgets/screen_layout.dart';
import '../widgets/pagination_controls.dart';
import '../core/ageOrDate.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Add Form State
  final nameController = TextEditingController();
  
  double? amount;
  AgeOrDate? startAt;
  DateTime? endAt;
  int? selectedFromId;
  int? selectedIntoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransferProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }
  
  void _clearForm() {
    nameController.clear();
    setState(() {
      amount = null;
      startAt = null;
      endAt = null;
      selectedFromId = null;
      selectedIntoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransferProvider, AccountProvider>(
      builder: (ctx, transferProv, accountProv, _) {
       final content = transferProv.isLoading 
         ? const Center(child: CircularProgressIndicator())
         : transferProv.error != null
             ? Center(child: Text('Error: ${transferProv.error}', style: const TextStyle(color: Colors.red)))
             : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transferProv.transfers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                        final t = transferProv.transfers[i];
                        
                        // Resolve names
                        final fromName = accountProv.accounts
                            .where((a) => a.id == t.fromAccount)
                            .map((a) => a.name)
                            .firstOrNull ?? 'Unknown';
                            
                        final intoName = accountProv.accounts
                            .where((a) => a.id == t.intoAccount)
                            .map((a) => a.name)
                            .firstOrNull ?? 'External';
                        
                        return ListTile(
                            title: Text(t.name),
                            subtitle: Text('$fromName -> $intoName | £${t.amount.toStringAsFixed(2)} | ${t.startAt}'),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTransfer(t)),
                                    IconButton(icon: const Icon(Icons.delete), onPressed: () => transferProv.delete(t.id!)),
                                ]
                            ),
                        );
                    },
                );

       return ScreenLayout(
         body: Column(
           children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Align(alignment: Alignment.centerLeft, child: Text('Transfers (${transferProv.transfers.length})', style: Theme.of(context).textTheme.headlineSmall)),
             ),
             Expanded(child: content),
             PaginationControls(
               page: transferProv.page,
               totalCount: transferProv.totalCount,
               limit: transferProv.limit,
               onPageChanged: transferProv.setPage,
               isLoading: transferProv.isLoading,
             ),
             const SizedBox(height: 8),
           ],
         ),
         sidebar: SingleChildScrollView(
           padding: const EdgeInsets.all(16),
           child: Form(
             key: _formKey,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Text('Add Transfer', style: Theme.of(context).textTheme.titleLarge),
                 const SizedBox(height: 20),
                 TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                 ),
                 const SizedBox(height: 12),
                 AccountDropdown(
                   selectedId: selectedFromId,
                   onChanged: (v) => setState(() => selectedFromId = v),
                   label: 'From Account',
                   nullable: false,
                 ),
                 const SizedBox(height: 12),
                 AccountDropdown(
                   selectedId: selectedIntoId,
                   onChanged: (v) => setState(() => selectedIntoId = v),
                   label: 'To Account',
                   nullable: false,
                 ),
                 const SizedBox(height: 12),
                 CurrencyInput(
                   value: amount,
                   onChanged: (v) => setState(() => amount = v),
                   label: 'Amount (£)',
                   hint: '0.00',
                 ),
                 const SizedBox(height: 12),
                 AgeOrDateInput(
                   initialValue: startAt,
                   onChanged: (v) => setState(() => startAt = v),
                   label: 'Start Date',
                   nullable: false,
                 ),
                 const SizedBox(height: 12),
                 AgeOrDateInput(
                   value: endAt,
                   onChanged: (v) => setState(() => endAt = v),
                   label: 'End Date (Optional)',
                   nullable: true,
                 ),
                 const SizedBox(height: 20),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.add),
                   label: const Text('Add Transfer'),
                   style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   onPressed: _saveNew,
                 ),
               ],
             ),
           ),
         ),
       );
      });
  }

  Future<void> _saveNew() async {
    if (!_formKey.currentState!.validate()) return;
    if (amount == null || startAt == null || selectedFromId == null || selectedIntoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
        return;
    }
    
    final transfer = Transfer(
       name: nameController.text.isEmpty ? 'Transfer' : nameController.text,
       fromAccount: selectedFromId!,
       intoAccount: selectedIntoId!,
       amount: amount!,
       startAt: startAt!,
       endAt: endAt,
       rate: 0.0,
    );
    
    final prov = Provider.of<TransferProvider>(context, listen: false);
    await prov.add(transfer);
    _clearForm();
  }

  void _editTransfer(Transfer item) {
    final nameCtl = TextEditingController(text: item.name);
    double? amt = item.amount;
    String? start = item.startAt;
    String? end = item.endAt;
    int? from = item.fromAccount;
    int? into = item.intoAccount;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Transfer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                TextFormField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name'),
                ),
                AccountDropdown(
                   selectedId: from,
                   onChanged: (v) => from = v,
                   label: 'From Account',
                ),
                AccountDropdown(
                   selectedId: into,
                   onChanged: (v) => into = v,
                   label: 'To Account',
                ),
                CurrencyInput(
                   value: amt,
                   onChanged: (v) => amt = v,
                   label: 'Amount',
                ),
                AgeOrDateInput(
                   value: start,
                   onChanged: (v) => start = v,
                   label: 'Start Date',
                   nullable: false,
                ),
                AgeOrDateInput(
                   value: end,
                   onChanged: (v) => end = v,
                   label: 'End Date',
                   nullable: true,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               if (amt==null || start==null || from==null || into==null) return;
                
               final updated = Transfer(
                  id: item.id,
                  name: nameCtl.text,
                  fromAccount: from!,
                  intoAccount: into!,
                  amount: amt!,
                  startAt: start!,
                  endAt: end,
                  rate: 0.0
               );
               
               await Provider.of<TransferProvider>(context, listen: false).update(updated);
               if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
