import '../../core/error/task_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// Hive-backed implementation of [TaskRepository].
///
/// Responsibilities:
///  * map between the domain [Task] and the storage [TaskModel];
///  * translate any low-level storage error into a [TaskException] so callers
///    depend on one predictable error type.
class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._dataSource);

  final TaskLocalDataSource _dataSource;

  @override
  Future<List<Task>> getTasks() {
    return _guard(
      () async =>
          _dataSource.getAll().map((model) => model.toEntity()).toList(),
      'load tasks',
    );
  }

  @override
  Future<void> addTask(Task task) {
    return _guard(
      () => _dataSource.put(TaskModel.fromEntity(task)),
      'add task',
    );
  }

  @override
  Future<void> updateTask(Task task) {
    return _guard(
      () => _dataSource.put(TaskModel.fromEntity(task)),
      'update task',
    );
  }

  @override
  Future<void> deleteTask(String id) {
    return _guard(() => _dataSource.delete(id), 'delete task');
  }

  /// Runs [action], wrapping any failure in a [TaskException] while preserving
  /// the original stack trace.
  Future<T> _guard<T>(Future<T> Function() action, String operation) async {
    try {
      return await action();
    } on TaskException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TaskException('Could not $operation. Please try again.', error),
        stackTrace,
      );
    }
  }
}
