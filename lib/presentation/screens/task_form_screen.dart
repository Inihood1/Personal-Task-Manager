import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Screen for creating a new task or editing an existing one.
///
/// A single screen serves both modes: [task] is `null` when adding and
/// non-null when editing.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  bool get isEditing => task != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final notifier = ref.read(taskListProvider.notifier);
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (widget.isEditing) {
      await notifier.editTask(
        id: widget.task!.id,
        title: title,
        description: description,
      );
    } else {
      await notifier.addTask(title: title, description: description);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    // The mutation reports failures via the provider's error state.
    if (ref.read(taskListProvider).hasError) {
      _showSnack('Could not save the task. Please try again.');
      return;
    }

    _showSnack(widget.isEditing ? 'Task updated' : 'Task added');
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmationDialog(context, widget.task!.title);
    if (!confirmed || !mounted) return;

    await ref.read(taskListProvider.notifier).deleteTask(widget.task!.id);
    if (!mounted) return;

    if (ref.read(taskListProvider).hasError) {
      _showSnack('Could not delete the task. Please try again.');
      return;
    }
    _showSnack('Task deleted');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit task' : 'New task'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete task',
              onPressed: _isSaving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('title-field'),
                controller: _titleController,
                autofocus: !widget.isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: AppConstants.maxTitleLength,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to be done?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('description-field'),
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                maxLength: AppConstants.maxDescriptionLength,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more details…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('save-button'),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(widget.isEditing ? 'Save changes' : 'Add task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
