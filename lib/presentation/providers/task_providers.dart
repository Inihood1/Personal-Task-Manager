import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../data/datasources/task_local_data_source.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

// ---------------------------------------------------------------------------
// Composition root
//
// Riverpod itself is used for dependency injection (no get_it/injectable).
// The Hive box is opened once in main() and injected via an override, which
// keeps async box-opening out of the widget tree and makes these providers
// trivial to override with fakes in tests.
// ---------------------------------------------------------------------------

/// Provides the opened Hive box. Overridden in `main()` after the box is ready.
final taskBoxProvider = Provider<Box<TaskModel>>(
  (ref) => throw UnimplementedError(
    'taskBoxProvider must be overridden with an opened box in main().',
  ),
);

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>(
  (ref) => TaskLocalDataSource(ref.watch(taskBoxProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskLocalDataSourceProvider)),
);

// ---------------------------------------------------------------------------
// Task list state (the "view model")
// ---------------------------------------------------------------------------

/// Owns the task list and all mutations.
///
/// Follows the idiomatic Riverpod 3 pattern: [build] loads the list from the
/// repository, and every mutation writes to the repository then reloads inside
/// [AsyncValue.guard] — which captures errors into an [AsyncError] state and
/// always publishes a brand-new list instance (so listeners are notified).
class TaskListNotifier extends AsyncNotifier<List<Task>> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  Future<List<Task>> build() => _repository.getTasks();

  /// Creates a task from user input. Id and timestamps are generated here.
  Future<void> addTask({
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    state = await AsyncValue.guard(() async {
      await _repository.addTask(task);
      return _repository.getTasks();
    });
  }

  /// Edits the title/description of an existing task.
  Future<void> editTask({
    required String id,
    required String title,
    required String description,
  }) async {
    state = await AsyncValue.guard(() async {
      final current = await _repository.getTasks();
      final existing = current.firstWhere((task) => task.id == id);
      await _repository.updateTask(
        existing.copyWith(
          title: title.trim(),
          description: description.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      return _repository.getTasks();
    });
  }

  /// Flips the completion status of a task.
  Future<void> toggleComplete(String id) async {
    state = await AsyncValue.guard(() async {
      final current = await _repository.getTasks();
      final existing = current.firstWhere((task) => task.id == id);
      await _repository.updateTask(
        existing.copyWith(
          isCompleted: !existing.isCompleted,
          updatedAt: DateTime.now(),
        ),
      );
      return _repository.getTasks();
    });
  }

  /// Deletes a task by id.
  Future<void> deleteTask(String id) async {
    state = await AsyncValue.guard(() async {
      await _repository.deleteTask(id);
      return _repository.getTasks();
    });
  }

  /// Re-inserts a previously deleted task (used to power "undo").
  Future<void> restoreTask(Task task) async {
    state = await AsyncValue.guard(() async {
      await _repository.addTask(task);
      return _repository.getTasks();
    });
  }

  /// Reloads from storage, showing a loading state (used by pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.getTasks);
  }
}

final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// Holds the current search query. A small [Notifier] reads cleaner than the
/// legacy `StateProvider` in Riverpod 3.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Derived view of the task list: filtered by the search query and sorted for
/// display (active tasks first, then most-recently-updated first).
///
/// Filtering/sorting lives in a provider — not in a widget's `build` — so the
/// UI stays declarative and this logic is independently testable.
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return tasksAsync.whenData((tasks) {
    final result = query.isEmpty
        ? [...tasks]
        : tasks
            .where((task) =>
                task.title.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query))
            .toList();

    result.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return result;
  });
});
