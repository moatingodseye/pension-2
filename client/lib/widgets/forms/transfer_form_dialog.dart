import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/account_provider.dart';
import 'package:shared/models/transfer.dart';
import 'package:shared/models/ageOrDate.dart';
import '../currency_input.dart';
import '../age_or_date_input.dart';
import '../account_dropdown.dart';
import '../form_dialog.dart';
import '../compact_input.dart';

class TransferFormDialog extends StatefulWidget {
  final Transfer? transfer;

  const TransferFormDialog({super.key, this.transfer});

  @override
  State<TransferFormDialog> createState() => _TransferFormDialogState();
}

class _TransferFormDialogState extends State<TransferFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  
  double? _amount;
  AgeOrDate? _startAt;
  AgeOrDate? _endAt;
  int? _selectedFromId;
  int? _selectedIntoId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<AccountProvider>(context, listen: false).load();
    });

    final tr = widget.transfer;
    _nameController = TextEditingController(text: tr?.name ?? 'Transfer');
    _rateController = TextEditingController(text: tr != null ? (tr.rate * 100).toString() : '');
    
    if (tr != null) {
      _amount = tr.amount;
      _startAt = tr.startAt;
      _endAt = tr.endAt;
      _selectedFromId = tr.fromId;
      _selectedIntoId = tr.intoId;
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
    if (_selectedFromId == null || _selectedIntoId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From and To accounts are required')));
       return;
    }
    if (_selectedFromId == _selectedIntoId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From and To accounts must be different')));
        return;
    }

    setState(() => _isLoading = true);

    try {
      final rateVal = double.tryParse(_rateController.text) ?? 0.0;
      final transfer = Transfer(
        id: widget.transfer?.id,
        name: _nameController.text,
        amount: _amount!,
        fromId: _selectedFromId!,
        intoId: _selectedIntoId!,
        startAt: _startAt!,
        endAt: _endAt,
        rate: rateVal / 100.0,
      );

      final provider = Provider.of<TransferProvider>(context, listen: false);
      if (widget.transfer == null) {
        await provider.add(transfer);
      } else {
        await provider.update(transfer);
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
      title: widget.transfer == null ? 'Add Transfer' : 'Edit Transfer',
      saveLabel: widget.transfer == null ? 'Add' : 'Save',
      isLoading: _isLoading,
      onSave: _save,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
             CurrencyInput(
              value: _amount,
              onChanged: (v) => setState(() => _amount = v),
              label: 'Monthly Amount',
//              nullable: false,
            ),
            const SizedBox(height: 12),
            AccountDropdown(
              selectedId: _selectedFromId,
              onChanged: (v) => setState(() => _selectedFromId = v),
              label: 'From Account',
              hint: 'Select',
            ),
            const SizedBox(height: 12),
            AccountDropdown(
              selectedId: _selectedIntoId,
              onChanged: (v) => setState(() => _selectedIntoId = v),
              label: 'To Account',
              hint: 'Select',
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
