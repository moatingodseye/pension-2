import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../widgets/currency_input.dart';
import '../widgets/date_input.dart';
import '../widgets/screen_layout.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import '../widgets/pagination_controls.dart';
import 'package:shared/models/ageOrDate.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  
  // Edit logic controllers (simpler to keep local or re-init)
  // For the properties:
  AccountType selectedType = AccountType.pension;
  DateTime? selectedDate;
  double? amount;
  double? interestRate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  void _clearForm() {
    nameController.clear();
    setState(() {
         selectedDate = null;
         selectedType = AccountType.pension;
         amount = null;
         interestRate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (ctx, provider, _) {
       
      final content = provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
             ? Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)))
             : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.accounts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final acc = provider.accounts[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(acc.type.label[0])),
                    title: Text('${acc.name} (${acc.type.label})'),
                    subtitle: Text(
                        '£${acc.amount.toStringAsFixed(2)} | Date: ${acc.amountAt.toString().split('T')[0]} | Rate: ${(acc.rate*100).toStringAsFixed(1)}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editAccount(acc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.delete(acc.id!),
                        ),
                      ],
                    ),
                  );
                },
              );

      return ScreenLayout(
        body: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Align(alignment: Alignment.centerLeft, child: Text('Accounts (${provider.accounts.length})', style: Theme.of(context).textTheme.headlineSmall)),
             ),
             Expanded(child: content),
             PaginationControls(
               page: provider.page,
               totalCount: provider.totalCount,
               limit: provider.limit,
               onPageChanged: provider.setPage,
               isLoading: provider.isLoading,
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
                Text('Add Account', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                CurrencyInput(
                  value: amount,
                  onChanged: (val) {
                    setState(() {
                      amount = val;
                    });
                  },
                  label: 'Amount (£)',
                  hint: '0.00',
                ),
                const SizedBox(height: 12),
                DateInput(
                  value: selectedDate,
                  onChanged: (val) => setState(() => selectedDate = val),
                  label: 'Date (Balance At)',
                  nullable: false,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: interestRate != null ? (interestRate! * 100).toStringAsFixed(1) : '',
                  decoration: const InputDecoration(labelText: 'Interest Rate (%)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    setState(() => interestRate = parsed != null ? parsed / 100 : null);
                  },
                  validator: (val) => val == null || val.isEmpty ? 'Enter rate' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Account'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (amount == null || interestRate == null || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    
                    final newAccount = Account(
                      name: nameController.text,
                      amount: amount!,
                      type: selectedType,
                      amountAt: AgeOrDate(date:selectedDate!),
                      rate: interestRate!,
                    );
                    
                    provider.add(newAccount);
                    _clearForm();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _editAccount(Account acc) {
    // Local controllers for dialog
    final nameCtl = TextEditingController(text: acc.name);
    final amountCtl = TextEditingController(text: acc.amount.toString());
    final dateCtl = TextEditingController(text: acc.amountAt.toString().split('T')[0]);
    final rateCtl = TextEditingController(text: (acc.rate * 100).toString());
    AccountType type = acc.type;
    DateTime? date = acc.amountAt.date!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account'),
        content: Form(
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               DropdownButtonFormField<AccountType>(
                  initialValue: type,
                  items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                  onChanged: (v) => type = v!,
                  decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: amountCtl,
                decoration: const InputDecoration(labelText: 'Amount (£)'),
              ),
              TextFormField(
                controller: dateCtl,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                   final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
                   if(picked!=null) {
                     date = picked;
                     dateCtl.text = picked.toIso8601String().split('T')[0];
                   }
                }
              ),
              TextFormField(
                controller: rateCtl,
                decoration: const InputDecoration(labelText: 'Interest Rate'),
              ),
            ],
          ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               final amount = double.tryParse(amountCtl.text) ?? acc.amount;
               final rate = (double.tryParse(rateCtl.text) ?? (acc.rate * 100)) / 100.0;
               final d = date ?? acc.amountAt.date;
            
               final updated = Account(
                 id: acc.id,
                 name: nameCtl.text,
                 amount: amount,
                 type: type,
                 amountAt: AgeOrDate(date:d),
                 rate: rate,
               );

              Provider.of<AccountProvider>(context, listen: false).update(updated); 
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
