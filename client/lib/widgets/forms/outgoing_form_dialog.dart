import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/outgoing_provider.dart';
import '../../providers/account_provider.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/ageOrDate.dart';
import '../currency_input.dart';
import '../age_or_date_input.dart';
import '../account_dropdown.dart';
import '../form_dialog.dart';
import '../compact_input.dart';

class OutgoingFormDialog extends StatefulWidget {
  final Outgoing? outgoing;

  const OutgoingFormDialog({super.key, this.outgoing});

  @override
  State<OutgoingFormDialog> createState() => _OutgoingFormDialogState();
}

class _OutgoingFormDialogState extends State<OutgoingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  
  double? _amount;
  AgeOrDate? _startAt;
  AgeOrDate? _endAt;
  int? _selectedFromId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<AccountProvider>(context, listen: false).load();
    });

    final out = widget.outgoing;
    _nameController = TextEditingController(text: out?.name ?? '');
    _rateController = TextEditingController(text: out != null ? (out.rate * 100).toString() : '');
    
    if (out != null) {
      _amount = out.amount;
      _startAt = out.startAt;
      _endAt = out.endAt;
      _selectedFromId = out.fromId;
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
    if (_selectedFromId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      final rateVal = double.tryParse(_rateController.text) ?? 0.0;
      final outgoing = Outgoing(
        id: widget.outgoing?.id,
        name: _nameController.text,
        amount: _amount!,
        fromId: _selectedFromId!,
        startAt: _startAt!,
        endAt: _endAt,
        rate: rateVal / 100.0,
      );

      final provider = Provider.of<OutgoingProvider>(context, listen: false);
      if (widget.outgoing == null) {
        await provider.add(outgoing);
      } else {
        await provider.update(outgoing);
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
      title: widget.outgoing == null ? 'Add Outgoing' : 'Edit Outgoing',
      saveLabel: widget.outgoing == null ? 'Add' : 'Save',
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
//              nullable: false,
            ),
            const SizedBox(height: 12),
            AccountDropdown(
              selectedId: _selectedFromId,
              onChanged: (v) => setState(() => _selectedFromId = v),
              label: 'From Account',
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
