import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompactInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final bool isPercentage;
  final bool isCurrency;
  
  const CompactInput({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.controller,
    this.isPercentage = false,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine suffix
    Widget? suffix;
    if (isPercentage) suffix = const Padding(padding: EdgeInsets.only(right: 8), child: Text('%'));
    
    // Determine prefix
    Widget? prefix;
    if (isCurrency) prefix = const Padding(padding: EdgeInsets.only(left: 8, right: 4), child: Text('£'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
        ],
        SizedBox(
          width: 120, // Clean, compact fixed width
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            onChanged: onChanged,
            validator: validator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              hintText: hint ?? '0.00',
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
