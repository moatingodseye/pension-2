import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/income_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/income.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  
  int? selectedIntoId;
  int? currentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncomeProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  void _openDialog(Income? item) {
    if (item != null) {
      currentId = item.id;
      nameController.text = item.name;
      amountController.text = item.amount.toString();
      startController.text = item.startAt;
      endController.text = item.endAt ?? '';
      rateController.text = (item.rate * 100).toString();
      selectedIntoId = item.intoAccount;
    } else {
      currentId = null;
      nameController.clear();
      amountController.clear();
      startController.clear();
      endController.clear();
      rateController.clear();
      selectedIntoId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Income' : 'Edit Income'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name (e.g. Salary, State Pension)'),
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monthly Amount (£)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Enter amount' : null,
                ),
                Consumer<AccountProvider>(
                  builder: (ctx, accProv, _) {
                    return DropdownButtonFormField<int>(
                      value: selectedIntoId,
                      hint: const Text('Into Account (Optional)'),
                      items: [
                         const DropdownMenuItem<int>(value: null, child: Text('None (General Pot)')),
                         ...accProv.accounts.map((a) => DropdownMenuItem<int>(value: a.id, child: Text(a.name))),
                      ],
                      onChanged: (v) => setState(() => selectedIntoId = v),
                    );
                  }
                ),
                TextFormField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: 'Start (Age e.g. 68 or Date YYYY-MM-DD)'),
                  validator: (v) => v!.isEmpty ? 'Enter start' : null,
                ),
                TextFormField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: 'End (Optional: Age/Date/Empty)'),
                ),
                TextFormField(
                  controller: rateController,
                  decoration: const InputDecoration(labelText: 'Growth Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
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

  Future<void> _save(BuildContext ctx) async {
    final income = Income(
      id: currentId,
      name: nameController.text,
      amount: double.tryParse(amountController.text) ?? 0.0,
      intoAccount: selectedIntoId,
      startAt: startController.text,
      endAt: endController.text.isEmpty ? null : endController.text,
      rate: (double.tryParse(rateController.text) ?? 0.0) / 100.0,
    );

    final prov = Provider.of<IncomeProvider>(context, listen: false);
    if (currentId == null) {
      await prov.add(income);
    } else {
      await prov.update(income);
    }
    if (ctx.mounted) Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Incomes', style: TextStyle(fontSize: 24)),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.incomes.length,
                  itemBuilder: (ctx, i) {
                    final inc = provider.incomes[i];
                    return ListTile(
                      title: Text(inc.name),
                      subtitle: Text('£${inc.amount}/mo | Start: ${inc.startAt}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDialog(inc)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => provider.delete(inc.id!)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(onPressed: () => _openDialog(null), child: const Text('Add Income')),
            ],
          ),
        );
      },
    );
  }
}
