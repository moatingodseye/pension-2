import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/transfer.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int? selectedFromId;
  int? selectedIntoId;
  
  int? currentTransferId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransferProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  void _openDialog(Transfer? item) {
    if (item != null) {
      nameController.text = item.name;
      amountController.text = item.amount.toString();
      startDateController.text = item.startAt;
      endDateController.text = item.endAt ?? '';
      selectedFromId = item.fromAccount;
      selectedIntoId = item.intoAccount;
      currentTransferId = item.id;
      
      if (item.startAt.isNotEmpty && item.startAt.contains('-')) {
          selectedStartDate = DateTime.tryParse(item.startAt);
      }
      if (item.endAt != null && item.endAt!.contains('-')) {
          selectedEndDate = DateTime.tryParse(item.endAt!);
      }

    } else {
      nameController.clear();
      amountController.clear();
      startDateController.clear();
      endDateController.clear();
      selectedFromId = null;
      selectedIntoId = null;
      selectedStartDate = null;
      selectedEndDate = null;
      currentTransferId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Transfer' : 'Edit Transfer'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                Consumer<AccountProvider>(
                  builder: (ctx, accProv, _) {
                    return DropdownButtonFormField<int>(
                      value: selectedFromId,
                      hint: const Text('From Account'),
                      items: accProv.accounts
                          .map((a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(a.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedFromId = v),
                      validator: (v) => v == null ? 'Select source' : null,
                    );
                  }
                ),
                const SizedBox(height: 8),
                Consumer<AccountProvider>(
                  builder: (ctx, accProv, _) {
                    return DropdownButtonFormField<int>(
                      value: selectedIntoId,
                      hint: const Text('To Account'),
                      items: accProv.accounts
                          .map((a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(a.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedIntoId = v),
                      validator: (v) => v == null ? 'Select dest' : null,
                    );
                  }
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (£)'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
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
                  validator: (val) => val == null || val.isEmpty ? 'Select start date' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'End Date (Optional)',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(ctx, false),
                ),
                TextButton(
                  onPressed: () { startDateController.clear(); endDateController.clear(); }, 
                  child: const Text("Clear Dates")
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              _save(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final str = picked.toIso8601String().split('T')[0];
      if (isStart) {
        selectedStartDate = picked;
        startDateController.text = str;
      } else {
        selectedEndDate = picked;
        endDateController.text = str;
      }
    }
  }

  Future<void> _save(BuildContext ctx) async {
       final transfer = Transfer(
          id: currentTransferId,
          name: nameController.text.isEmpty ? 'Transfer' : nameController.text,
          fromAccount: selectedFromId!, // Validator checked this
          intoAccount: selectedIntoId!, // Validator checked this
          amount: double.tryParse(amountController.text) ?? 0.0,
          startAt: startDateController.text,
          endAt: endDateController.text.isEmpty ? null : endDateController.text,
          rate: 0.0,
      );
      
      final prov = Provider.of<TransferProvider>(context, listen: false);
      if (currentTransferId == null) {
          await prov.add(transfer);
      } else {
          await prov.update(transfer);
      }
      if (ctx.mounted) Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransferProvider, AccountProvider>(
      builder: (ctx, transferProv, accountProv, _) {
       if (transferProv.isLoading) return const Center(child: CircularProgressIndicator());
       
       if (transferProv.error != null) {
            return Center(child: Text('Error: ${transferProv.error}', style: const TextStyle(color: Colors.red)));
       }

       return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            children: [
                const Text('Transfers', style: TextStyle(fontSize: 24)),
                Expanded(
                    child: ListView.builder(
                        itemCount: transferProv.transfers.length,
                        itemBuilder: (ctx, i) {
                            final t = transferProv.transfers[i];
                            
                            // Resolve names using AccountProvider
                            // Note: accountProv.accounts might be empty if not loaded.
                            // But we call load() in initState.
                            
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
                                subtitle: Text('$fromName -> $intoName | £${t.amount} | ${t.startAt}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDialog(t)),
                                        IconButton(icon: const Icon(Icons.delete), onPressed: () => transferProv.delete(t.id!)),
                                    ]
                                ),
                            );
                        },
                    ),
                ),
                ElevatedButton(onPressed: () => _openDialog(null), child: const Text('Add Transfer'))
            ]
        )
       );
      });
  }
}
