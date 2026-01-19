import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  
  AccountType selectedType = AccountType.pension;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }
  
  void _clearForm() {
    amountController.clear();
    dateController.clear();
    interestController.clear();
    nameController.clear();
    setState(() {
         selectedDate = null;
         selectedType = AccountType.pension;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (ctx, provider, _) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Accounts', style: TextStyle(fontSize: 24)),
            Expanded(
              child: ListView.builder(
                itemCount: provider.accounts.length,
                itemBuilder: (ctx, i) {
                  final acc = provider.accounts[i];
                  
                  return ListTile(
                    leading: CircleAvatar(child: Text(acc.type.label[0])),
                    title: Text('${acc.name} (${acc.type.label})'),
                    subtitle: Text(
                        '£${acc.amount} | Date: ${acc.amountAt.toIso8601String().split('T')[0]} | Rate: ${(acc.rate*100).toStringAsFixed(1)}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editAccount(acc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              provider.delete(acc.id!),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<AccountType>(
                      value: selectedType,
                      items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountController,
                      decoration:
                          const InputDecoration(labelText: 'Amount (£)'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (amountat)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _pickDate(context),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Select date' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: interestController,
                      decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter rate' : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final amount = double.tryParse(amountController.text);
                        final rate = double.tryParse(interestController.text);
                        if (amount == null || rate == null || selectedDate == null) {
                          return;
                        }
                        
                        final newAccount = Account(
                          name: nameController.text,
                          amount: amount,
                          type: selectedType,
                          amountAt: selectedDate!,
                          rate: rate / 100.0,
                          age: 0
                        );
                        
                        provider.add(newAccount);
                        _clearForm();
                      },
                      child: const Text('Add Account'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _editAccount(Account acc) {
    nameController.text = acc.name;
    amountController.text = acc.amount.toString();
    dateController.text = acc.amountAt.toIso8601String().split('T')[0];
    interestController.text = (acc.rate * 100).toString();
    selectedType = acc.type;
    selectedDate = acc.amountAt;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account'),
        content: Form(
          child: SingleChildScrollView(
          child: Column(
            children: [
               DropdownButtonFormField<AccountType>(
                  value: selectedType,
                  items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                  onChanged: (v) => selectedType = v!,
                  decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: amountController,
                decoration:
                    const InputDecoration(labelText: 'Amount (£)'),
              ),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                   final picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
                   if(picked!=null) dateController.text = picked.toIso8601String().split('T')[0];
                }
              ),
              TextFormField(
                controller: interestController,
                decoration:
                    const InputDecoration(labelText: 'Interest Rate'),
              ),
            ],
          ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               final amount = double.tryParse(amountController.text) ?? acc.amount;
               final rate = (double.tryParse(interestController.text) ?? (acc.rate * 100)) / 100.0;
               final date = DateTime.tryParse(dateController.text) ?? acc.amountAt;
            
               final updated = Account(
                 id: acc.id,
                 name: nameController.text,
                 amount: amount,
                 type: selectedType,
                 amountAt: date,
                 rate: rate,
                 age: acc.age
               );

              Provider.of<AccountProvider>(context, listen: false).update(updated); 
              Navigator.of(ctx).pop();
              _clearForm(); 
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
