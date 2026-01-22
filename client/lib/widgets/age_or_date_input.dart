import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/ageOrDate.dart';

/// A flexible input widget that accepts either an age (number) or a date (YYYY-MM-DD).
/// Used for Income/Outgoing/Transfer start/end fields where user can specify:
/// - Age relative to user (e.g., "68" for state pension age)
/// - Specific date (e.g., "2025-01-01" for work start date)
class AgeOrDateInput extends StatefulWidget {
  final AgeOrDate? initialValue;
  final ValueChanged<AgeOrDate> onChanged;
  final String? label;
  final String? hint;
  final bool nullable;
  final bool enabled;
  final String? errorText;

  const AgeOrDateInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.label,
    this.hint,
    this.nullable = true,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<AgeOrDateInput> createState() => _AgeOrDateInputState();
}

class _AgeOrDateInputState extends State<AgeOrDateInput> {
  late TextEditingController _controller;
  final _dateFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  final _ageFormat = RegExp(r'^\d{1,3}$');
  bool _isEditing = false;
  AgeOrDate? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(
      text: _currentValue?.toString() ?? '',
    );  }

  @override
  void didUpdateWidget(AgeOrDateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing) return;
    if (widget.initialValue != oldWidget.initialValue) {
      _currentValue = widget.initialValue;
      _controller.text = _currentValue?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDate(String value) {
    return _dateFormat.hasMatch(value);
  }

  bool _isAge(String value) {
    return _ageFormat.hasMatch(value);
  }

  void _handleTextChanged(String value) {
    _isEditing = true;

    if (value.isEmpty) {
      if (widget.nullable) {
        widget.onChanged(AgeOrDate(date:null,age:null));
      }
      return;
    }

    // Accept both age and date formats
    if (_isAge(value)) {
      widget.onChanged(AgeOrDate(date:null, age:int.tryParse(value)));  // Set age, null for date
    } else if (_isDate(value)) {
      final date = DateTime.tryParse(value);
      widget.onChanged(AgeOrDate(date:date, age: null));  // Set date, null for age
    }
  }

  Future<void> _showDatePicker() async {
    final initialDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _controller.text = formatted;
      });
      widget.onChanged(AgeOrDate(date:picked,age:null));
    }
  }

  void _clearValue() {
    if (widget.nullable) {
      setState(() {
        _controller.text = '';
      });
      widget.onChanged(AgeOrDate(date:null,age:null));
    }
  }

  void _formatOnBlur() {
    _isEditing = false;
    if (_controller.text.isEmpty) return;
  }

  String? _getHelperText() {
    final text = _controller.text;
    if (text.isEmpty) return null;
    
    if (_isAge(text)) {
      return 'Age: $text years old';
    } else if (_isDate(text)) {
      return 'Date: $text';
    }
    return 'Enter age (e.g., 68) or date (YYYY-MM-DD)';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
        LengthLimitingTextInputFormatter(10), // Max for YYYY-MM-DD
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? 'Age (68) or Date (YYYY-MM-DD)',
        errorText: widget.errorText,
        helperText: _getHelperText(),
        helperMaxLines: 1,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.nullable && _controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: widget.enabled ? _clearValue : null,
                tooltip: 'Clear',
              ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: widget.enabled ? _showDatePicker : null,
              tooltip: 'Pick date',
            ),
          ],
        ),
      ),
      onChanged: _handleTextChanged,
      onEditingComplete: _formatOnBlur,
    );
  }
}
