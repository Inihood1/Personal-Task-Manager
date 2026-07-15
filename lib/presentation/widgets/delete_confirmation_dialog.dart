import 'package:flutter/material.dart';

/// Shows a confirmation dialog before a destructive delete.
///
/// Returns `true` only if the user explicitly confirms; dismissing the dialog
/// (tap outside / back) resolves to `false`. Kept as a plain function so the
/// confirmation flow stays in the UI layer, away from the notifier.
Future<bool> showDeleteConfirmationDialog(
  BuildContext context,
  String taskTitle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Are you sure you want to delete "$taskTitle"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
