import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/models/account.dart';
import '../providers/account_provider.dart';

/// A dropdown widget for selecting accounts.
/// Shows account name and type, stores account ID.
class AccountDropdown extends StatelessWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String? label;
  final bool nullable;
  final bool enabled;
  final String? errorText;
  final String? hint;

  const AccountDropdown({
    super.key,
    this.selectedId,
    required this.onChanged,
    this.label,
    this.nullable = true,
    this.enabled = true,
    this.errorText,
    this.hint,
  });

  String _getAccountLabel(Account account) {
    return '${account.name} (${account.type.name})';
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(context);
    final accounts = accountProvider.accounts;

    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (nullable)
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('None'),
          ),
        ...accounts.map((account) {
          return DropdownMenuItem<int?>(
            value: account.id,
            child: Text(_getAccountLabel(account)),
          );
        }),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
