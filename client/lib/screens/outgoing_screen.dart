import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/outgoing_provider.dart';
import '../providers/account_provider.dart';
import 'package:shared/models/outgoing.dart';

class OutgoingScreen extends StatefulWidget {
  const OutgoingScreen({super.key});

  @override
  State<OutgoingScreen> createState() => _OutgoingScreenState();
}

class _OutgoingScreenState extends State<OutgoingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  
  int? selectedFromId;
  int? currentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OutgoingProvider>(context, listen: false).load();
      Provider.of<AccountProvider>(context, listen: false).load();
    });
  }

  void _openDialog(Outgoing? item) {
    if (item != null) {
      currentId = item.id;
      nameController.text = item.name;
      amountController.text = item.amount.toString();
      startController.text = item.startAt;
      endController.text = item.endAt ?? '';
      rateController.text = (item.rate * 100).toString();
      selectedFromId = item.fromAccount;
    } else {
      currentId = null;
      nameController.clear();
      amountController.clear();
      startController.clear();
      endController.clear();
      rateController.clear();
      selectedFromId = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Add Outgoing' : 'Edit Outgoing'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name (e.g. Rent, Bills)'),
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
                      initialValue: selectedFromId,
                      hint: const Text('From Account (Optional)'),
                      items: [
                         const DropdownMenuItem<int>(value: null, child: Text('Any (General Pot)')),
                         ...accProv.accounts.map((a) => DropdownMenuItem<int>(value: a.id, child: Text(a.name))),
                      ],
                      onChanged: (v) => setState(() => selectedFromId = v),
                    );
                  }
                ),
                TextFormField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: 'Start (Age e.g. 60 or Date YYYY-MM-DD)'),
                  validator: (v) => v!.isEmpty ? 'Enter start' : null,
                ),
                TextFormField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: 'End (Optional: Age/Date/Empty)'),
                ),
                TextFormField(
                  controller: rateController,
                  decoration: const InputDecoration(labelText: 'Inflation Rate (%)'),
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
    final outgoing = Outgoing(
      id: currentId,
      name: nameController.text,
      amount: double.tryParse(amountController.text) ?? 0.0,
      fromAccount: selectedFromId,
      startAt: startController.text,
      endAt: endController.text.isEmpty ? null : endController.text,
      rate: (double.tryParse(rateController.text) ?? 0.0) / 100.0,
    );

    final prov = Provider.of<OutgoingProvider>(context, listen: false);
    if (currentId == null) {
      await prov.add(outgoing);
    } else {
      await prov.update(outgoing);
    }
    if (ctx.mounted) Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OutgoingProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Outgoings', style: TextStyle(fontSize: 24)),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.outgoings.length,
                  itemBuilder: (ctx, i) {
                    final out = provider.outgoings[i];
                    return ListTile(
                      title: Text(out.name),
                      subtitle: Text('£${out.amount}/mo | Start: ${out.startAt}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDialog(out)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => provider.delete(out.id!)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(onPressed: () => _openDialog(null), child: const Text('Add Outgoing')),
            ],
          ),
        );
      },
    );
  }
}
