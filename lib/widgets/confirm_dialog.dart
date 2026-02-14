import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor:
                confirmColor ?? Theme.of(context).colorScheme.error,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => ConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor,
          ),
        ) ??
        false;
  }
}
