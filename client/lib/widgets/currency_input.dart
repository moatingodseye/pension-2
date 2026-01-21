import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A text input widget for UK Sterling currency amounts.
/// Displays £ symbol and formats numbers with commas.
class CurrencyInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  const CurrencyInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<CurrencyInput> createState() => _CurrencyInputState();
}

class _CurrencyInputState extends State<CurrencyInput> {
  late TextEditingController _controller;
  final _formatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.value!.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(CurrencyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value != null ? widget.value!.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    if (value.isEmpty) {
      widget.onChanged(null);
      return;
    }

    // Remove any non-numeric characters except decimal point
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(cleaned);
    widget.onChanged(parsed);
  }

  void _formatOnBlur() {
    if (_controller.text.isEmpty) return;
    
    final cleaned = _controller.text.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(cleaned);
    
    if (parsed != null) {
      _controller.text = parsed.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0.00',
        prefixText: '£ ',
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
      ),
      onChanged: _handleChanged,
      onEditingComplete: _formatOnBlur,
      onTapOutside: (_) => _formatOnBlur(),
    );
  }
}
