import '../entities/task.dart';

/// Contract for reading and writing tasks.
///
/// This abstraction is the seam between business logic and storage: the
/// presentation layer depends only on this interface, while the data layer
/// provides a concrete Hive-backed implementation. It also makes the notifier
/// trivial to unit-test against an in-memory fake.
abstract interface class TaskRepository {
  /// Returns all persisted tasks (unordered — ordering is a UI concern).
  Future<List<Task>> getTasks();

  /// Inserts a new task, or overwrites an existing one with the same id.
  Future<void> addTask(Task task);

  /// Updates an existing task.
  Future<void> updateTask(Task task);

  /// Deletes the task with the given [id]. A no-op if it does not exist.
  Future<void> deleteTask(String id);
}
