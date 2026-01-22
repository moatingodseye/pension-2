import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/outgoing_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/outgoing.dart';
import '../widgets/currency_input.dart';
import '../widgets/age_or_date_input.dart';
import '../widgets/account_dropdown.dart';
import '../widgets/screen_layout.dart';
import '../widgets/pagination_controls.dart';

class OutgoingScreen extends StatefulWidget {
  const OutgoingScreen({super.key});

  @override
  State<OutgoingScreen> createState() => _OutgoingScreenState();
}

class _OutgoingScreenState extends State<OutgoingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Add Form State
  final nameController = TextEditingController();
  final rateController = TextEditingController(); 
  
  double? amount; 
  int? age;
  String? startAt; 
  String? endAt; 
  
  int? selectedFromId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OutgoingProvider>(context, listen: false).load();
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
      selectedFromId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OutgoingProvider>(
      builder: (ctx, provider, _) {
        final content = provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.outgoings.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final out = provider.outgoings[i];
                    return ListTile(
                      title: Text(out.name),
                      subtitle: Text('£${out.amount.toStringAsFixed(2)}/mo | Start: ${out.startAt}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editOutgoing(out)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => provider.delete(out.id!)),
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
                 child: Align(alignment: Alignment.centerLeft, child: Text('Outgoings (${provider.outgoings.length})', style: Theme.of(context).textTheme.headlineSmall)),
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
                  Text('Add Outgoing', style: Theme.of(context).textTheme.titleLarge),
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
                    selectedId: selectedFromId,
                    onChanged: (v) => setState(() => selectedFromId = v),
                    label: 'From Account (Optional)',
                    hint: 'Any (General Pot)',
                  ),
                  const SizedBox(height: 12),
                  AgeOrDateInput(
                    date: startAt,
                    age: age;
                    onChanged: (v) => setState(() => startAt = v),
                    label: 'Start (Age/Date)',
                    nullable: false,
                  ),
                  const SizedBox(height: 12),
                  AgeOrDateInput(
                    value: endAt,
                    onChanged: (v) => setState(() => endAt = v),
                    label: 'End (Optional)',
                    nullable: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rateController,
                    decoration: const InputDecoration(labelText: 'Inflation Rate (%)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Outgoing'),
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
    
    final outgoing = Outgoing(
      name: nameController.text,
      amount: amount!,
      fromAccount: selectedFromId,
      startAt: startAt!,
      endAt: endAt,
      rate: (double.tryParse(rateController.text) ?? 0.0) / 100.0,
    );

    final prov = Provider.of<OutgoingProvider>(context, listen: false);
    await prov.add(outgoing);
    _clearForm();
  }
  
  void _editOutgoing(Outgoing item) {
    // Local controllers
    final nameCtl = TextEditingController(text: item.name);
    final rateCtl = TextEditingController(text: (item.rate * 100).toString());
    double? amt = item.amount;
    String? start = item.startAt;
    String? end = item.endAt;
    int? from = item.fromAccount;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Outgoing'),
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
                  selectedId: from,
                  onChanged: (v) => from = v,
                  label: 'From Account',
                ),
                AgeOrDateInput(
                  value: start,
                  onChanged: (v) => start = v,
                  label: 'Start',
                  nullable: false,
                ),
                AgeOrDateInput(
                  value: end,
                  onChanged: (v) => end = v,
                  label: 'End',
                  nullable: true,
                ),
                TextFormField(
                  controller: rateCtl,
                  decoration: const InputDecoration(labelText: 'Inflation Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (amt == null || start == null) return;
              
              final updated = Outgoing(
                id: item.id,
                name: nameCtl.text,
                amount: amt!,
                fromAccount: from,
                startAt: start!,
                endAt: end,
                rate: (double.tryParse(rateCtl.text) ?? 0.0) / 100.0,
              );
              
              await Provider.of<OutgoingProvider>(context, listen: false).update(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
