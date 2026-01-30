import 'package:flutter/material.dart';

class FormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final String cancelLabel;
  final bool isLoading;

  const FormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    this.onCancel,
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // We wrap in a Dialog but use a custom design for consistent branding
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),
              const Divider(height: 1),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : (onCancel ?? () => Navigator.of(context).pop()),
                      child: Text(cancelLabel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : onSave,
                      child: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(saveLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
