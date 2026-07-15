import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import 'delete_confirmation_dialog.dart';

/// A single row in the task list.
///
/// Swipe left to delete (guarded by a confirmation dialog and offering an undo
/// snackbar), tap the checkbox to toggle completion, or tap the body to edit.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, required this.onEdit});

  final Task task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(taskListProvider.notifier);

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(color: theme.colorScheme.errorContainer),
      confirmDismiss: (_) => showDeleteConfirmationDialog(context, task.title),
      onDismissed: (_) async {
        await notifier.deleteTask(task.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('"${task.title}" deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => notifier.restoreTask(task),
              ),
            ),
          );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => notifier.toggleComplete(task.id),
          ),
          title: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                formatTaskDate(task.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onEdit,
        ),
      ),
    );
  }
}

/// Red swipe-to-delete background with a trash icon.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(Icons.delete_outline_rounded),
    );
  }
}
