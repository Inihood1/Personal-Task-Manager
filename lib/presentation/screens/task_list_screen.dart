import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/task.dart';
import '../providers/task_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/task_search_field.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

/// Home screen: shows the (searchable) task list with loading, empty and error
/// states, and a button to add a new task.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  void _openForm(BuildContext context, {Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasks = ref.watch(filteredTasksProvider);
    final query = ref.watch(searchQueryProvider);
    final totalCount = ref.watch(taskListProvider).value?.length ?? 0;
    final showSearch = totalCount > 0 || query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showSearch) const TaskSearchField(),
            Expanded(
              child: filteredTasks.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () =>
                      ref.read(taskListProvider.notifier).refresh(),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return EmptyState(
                      isSearching: query.isNotEmpty,
                      query: query,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(taskListProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskTile(
                          task: task,
                          onEdit: () => _openForm(context, task: task),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
