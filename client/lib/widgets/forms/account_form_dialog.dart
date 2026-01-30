import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/ageOrDate.dart';
import '../currency_input.dart';
import '../date_input.dart';
import '../form_dialog.dart';
import '../compact_input.dart';

class AccountFormDialog extends StatefulWidget {
  final Account? account; // If null, Add mode

  const AccountFormDialog({super.key, this.account});

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController; // Using CompactInput or standard?
  
  AccountType _selectedType = AccountType.pension;
  DateTime? _selectedDate;
  double? _amount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _nameController = TextEditingController(text: acc?.name ?? '');
    _rateController = TextEditingController(text: acc != null ? (acc.rate * 100).toString() : '');
    
    if (acc != null) {
      _selectedType = acc.type;
      _selectedDate = acc.amountAt.date;
      _amount = acc.amount;
    } else {
      _selectedDate = DateTime.now(); // Default to today for new accounts?
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount == null || _selectedDate == null) {
        // Validation handled by widgets usually, but double check
        return;
    }

    setState(() => _isLoading = true);

    try {
      final rateVal = double.tryParse(_rateController.text) ?? 0.0;
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text,
        amount: _amount!,
        type: _selectedType,
        amountAt: AgeOrDate(date: _selectedDate!),
        rate: rateVal / 100.0,
      );

      final provider = Provider.of<AccountProvider>(context, listen: false);
      if (widget.account == null) {
        await provider.add(account);
      } else {
        await provider.update(account);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.account == null ? 'Add Account' : 'Edit Account',
      saveLabel: widget.account == null ? 'Add' : 'Save',
      isLoading: _isLoading,
      onSave: _save,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              items: AccountType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CurrencyInput(
              value: _amount,
              onChanged: (v) => setState(() => _amount = v),
              label: 'Amount',
//              nullable: false,
            ),
            const SizedBox(height: 12),
            DateInput(
              value: _selectedDate,
              onChanged: (v) => setState(() => _selectedDate = v),
              label: 'Date (Balance At)',
              nullable: false,
            ),
            const SizedBox(height: 12),
            CompactInput(
              label: 'Interest Rate',
              controller: _rateController,
              isPercentage: true,
              hint: '0.0',
            ),
          ],
        ),
      ),
    );
  }
}
