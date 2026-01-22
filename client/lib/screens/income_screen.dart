import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/income_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/income.dart';
import '../widgets/currency_input.dart';
import '../widgets/age_or_date_input.dart';
import '../widgets/account_dropdown.dart';
import '../widgets/screen_layout.dart';
import '../widgets/pagination_controls.dart';
import '../core/ageOrDate.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Add Form State
  final nameController = TextEditingController();
  final rateController = TextEditingController(); 
  
  double? amount; 
  AgeOrDate? startAt; 
  AgeOrDate? endAt; 
  
  int? selectedIntoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncomeProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }
  
  void _clearForm() {
    nameController.clear();
    rateController.clear();
    setState(() {
      amount = null;
      startAt = null;
      endAt = null;
      selectedIntoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeProvider>(
      builder: (ctx, provider, _) {
        final content = provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.incomes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final inc = provider.incomes[i];
                    return ListTile(
                      title: Text(inc.name),
                      subtitle: Text('£${inc.amount.toStringAsFixed(2)}/mo | Start: ${inc.startAt}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editIncome(inc)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => provider.delete(inc.id!)),
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
                 child: Align(alignment: Alignment.centerLeft, child: Text('Incomes (${provider.incomes.length})', style: Theme.of(context).textTheme.headlineSmall)),
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
                  Text('Add Income', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  CurrencyInput(
                    value: amount,
                    onChanged: (v) => setState(() => amount = v),
                    label: 'Monthly Amount',
                    hint: '0.00',
                  ),
                  const SizedBox(height: 12),
                  AccountDropdown(
                    selectedId: selectedIntoId,
                    onChanged: (v) => setState(() => selectedIntoId = v),
                    label: 'Into Account (Optional)',
                    hint: 'None (General Pot)',
                  ),
                  const SizedBox(height: 12),
                  AgeOrDateInput(
                    initialValue: startAt,
                    onChanged: (v) => setState(() => startAt = v),
                    label: 'Start (Age/Date)',
                    nullable: false,
                  ),
                  const SizedBox(height: 12),
                  AgeOrDateInput(
                    initialValue: endAt,
                    onChanged: (v) => setState(() => endAt = v),
                    label: 'End (Optional)',
                    nullable: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rateController,
                    decoration: const InputDecoration(labelText: 'Growth Rate (%)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
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
      },
    );
  }

  Future<void> _saveNew() async {
    if (!_formKey.currentState!.validate()) return;
    if (amount == null || startAt == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount and Start Date are required')));
       return;
    }
    
    final income = Income(
      name: nameController.text,
      amount: amount!,
      intoId: selectedIntoId,
      startAt: startAt!,
      endAt: endAt,
      rate: (double.tryParse(rateController.text) ?? 0.0) / 100.0,
    );

    final prov = Provider.of<IncomeProvider>(context, listen: false);
    await prov.add(income);
    _clearForm();
  }
  
  void _editIncome(Income item) {
    // Local controllers
    final nameCtl = TextEditingController(text: item.name);
    final rateCtl = TextEditingController(text: (item.rate * 100).toString());
    double? amt = item.amount;
    int? age = item.age;
    DateTime? starAt = item.startAt;
    DateTime? endAt = item.endAt;
    int? intoId = item.intoId;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Income'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                CurrencyInput(
                  value: amt,
                  onChanged: (v) => amt = v,
                  label: 'Monthly Amount',
                ),
                AccountDropdown(
                  selectedId: intoId,
                  onChanged: (v) => intoId = v,
                  label: 'Into Account',
                ),
                AgeOrDateInput(
                  initialValue: AgeOrDatae(date: startAt, age: age),
                  onChanged: (v) => startAt = v,
                  label: 'Start',
                  nullable: false,
                ),
                AgeOrDateInput(
                  initialValue: AgeOrDate(date: endAt, age:null),
                  onChanged: (v) => endAt = v,
                  label: 'End',
                  nullable: true,
                ),
                TextFormField(
                  controller: rateCtl,
                  decoration: const InputDecoration(labelText: 'Growth Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (amt == null || startAt == null) return;
              
              final updated = Income(
                id: item.id,
                name: nameCtl.text,
                amount: amt!,
                intoId: intoId,
                age: age!,
                startAt: startAt!,
                endAt: endAt,
                rate: (double.tryParse(rateCtl.text) ?? 0.0) / 100.0,
              );
              
              await Provider.of<IncomeProvider>(context, listen: false).update(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
