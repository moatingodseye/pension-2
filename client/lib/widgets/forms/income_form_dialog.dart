import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/account_provider.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/ageOrDate.dart';
import '../currency_input.dart';
import '../age_or_date_input.dart';
import '../account_dropdown.dart';
import '../form_dialog.dart';
import '../compact_input.dart';

class IncomeFormDialog extends StatefulWidget {
  final Income? income; // If null, Add mode

  const IncomeFormDialog({super.key, this.income});

  @override
  State<IncomeFormDialog> createState() => _IncomeFormDialogState();
}

class _IncomeFormDialogState extends State<IncomeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  
  double? _amount;
  AgeOrDate? _startAt;
  AgeOrDate? _endAt;
  int? _selectedIntoId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load accounts if not loaded? Provider usually handles it but good check
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<AccountProvider>(context, listen: false).load();
    });

    final inc = widget.income;
    _nameController = TextEditingController(text: inc?.name ?? '');
    _rateController = TextEditingController(text: inc != null ? (inc.rate * 100).toString() : '');
    
    if (inc != null) {
      _amount = inc.amount;
      _startAt = inc.startAt;
      _endAt = inc.endAt;
      _selectedIntoId = inc.intoId;
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
    if (_amount == null || _startAt == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount and Start are required')));
       return;
    }
    if (_selectedIntoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
        return;
    }

    setState(() => _isLoading = true);

    try {
      final rateVal = double.tryParse(_rateController.text) ?? 0.0;
      final income = Income(
        id: widget.income?.id,
        name: _nameController.text,
        amount: _amount!,
        intoId: _selectedIntoId, // Optional
        startAt: _startAt!,
        endAt: _endAt,
        rate: rateVal / 100.0,
      );

      final provider = Provider.of<IncomeProvider>(context, listen: false);
      if (widget.income == null) {
        await provider.add(income);
      } else {
        await provider.update(income);
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
      title: widget.income == null ? 'Add Income' : 'Edit Income',
      saveLabel: widget.income == null ? 'Add' : 'Save',
      isLoading: _isLoading,
      onSave: _save,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CurrencyInput(
              value: _amount,
              onChanged: (v) => setState(() => _amount = v),
              label: 'Monthly Amount',
              nullable: false,
            ),
            const SizedBox(height: 12),
            AccountDropdown(
              selectedId: _selectedIntoId,
              onChanged: (v) => setState(() => _selectedIntoId = v),
              label: 'Into Account',
              hint: 'Select Account',
            ),
            const SizedBox(height: 12),
            AgeOrDateInput(
              initialValue: _startAt,
              onChanged: (v) => setState(() => _startAt = v),
              label: 'Start (Age/Date)',
              nullable: false,
            ),
            const SizedBox(height: 12),
            AgeOrDateInput(
              initialValue: _endAt,
              onChanged: (v) => setState(() => _endAt = v),
              label: 'End (Optional)',
              nullable: true,
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
