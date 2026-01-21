import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A date input widget that supports both manual text entry and date picker.
/// Handles nullable dates gracefully with an optional clear button.
class DateInput extends StatefulWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? label;
  final String? hint;
  final bool nullable;
  final bool enabled;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.nullable = true,
    this.enabled = true,
    this.errorText,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  late TextEditingController _controller;
  final _dateFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? _formatDate(widget.value!) : '',
    );
  }

  @override
  void didUpdateWidget(DateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value != null ? _formatDate(widget.value!) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _handleTextChanged(String value) {
    if (value.isEmpty) {
      if (widget.nullable) {
        widget.onChanged(null);
      }
      return;
    }

    // Validate format YYYY-MM-DD
    if (_dateFormat.hasMatch(value)) {
      try {
        final date = DateTime.parse(value);
        widget.onChanged(date);
      } catch (e) {
        // Invalid date, don't update
      }
    }
  }

  Future<void> _showDatePicker() async {
    final initialDate = widget.value ?? DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _controller.text = _formatDate(picked);
      });
      widget.onChanged(picked);
    }
  }

  void _clearDate() {
    if (widget.nullable) {
      setState(() {
        _controller.text = '';
      });
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
        LengthLimitingTextInputFormatter(10), // YYYY-MM-DD
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? 'YYYY-MM-DD',
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.nullable && _controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: widget.enabled ? _clearDate : null,
                tooltip: 'Clear date',
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
    );
  }
}
