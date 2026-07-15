import 'package:flutter/material.dart';

/// A centered illustration + message shown when there is nothing to display.
///
/// Distinguishes two cases so the message is always meaningful:
///  * no tasks exist yet, or
///  * a search returned no matches.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.isSearching,
    this.query = '',
  });

  /// Whether an active search produced the empty result.
  final bool isSearching;

  /// The current search query (used in the "no matches" message).
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = isSearching ? Icons.search_off_rounded : Icons.checklist_rounded;
    final title = isSearching ? 'No matching tasks' : 'No tasks yet';
    final subtitle = isSearching
        ? 'Nothing matches "$query".'
        : 'Tap the + button to add your first task.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
