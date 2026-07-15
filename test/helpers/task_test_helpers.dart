import 'package:personal_task_manager/core/error/task_exception.dart';
import 'package:personal_task_manager/domain/entities/task.dart';
import 'package:personal_task_manager/domain/repositories/task_repository.dart';

/// Builds a [Task] with sensible, deterministic defaults for tests.
Task sampleTask({
  required String id,
  String title = 'Sample task',
  String description = '',
  bool isCompleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime(2026, 7, 15, 12);
  return Task(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    createdAt: created,
    updatedAt: updatedAt ?? created,
  );
}

/// In-memory [TaskRepository] for fast, disk-free unit/widget tests.
///
/// Failure flags let tests exercise the error paths without touching Hive.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository([List<Task>? initial]) : _tasks = [...?initial];

  final List<Task> _tasks;

  bool failOnGet = false;
  bool failOnWrite = false;

  void seed(List<Task> tasks) {
    _tasks
      ..clear()
      ..addAll(tasks);
  }

  @override
  Future<List<Task>> getTasks() async {
    if (failOnGet) throw const TaskException('Simulated read failure');
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(Task task) async {
    if (failOnWrite) throw const TaskException('Simulated write failure');
    _tasks
      ..removeWhere((t) => t.id == task.id)
      ..add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    if (failOnWrite) throw const TaskException('Simulated write failure');
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    if (failOnWrite) throw const TaskException('Simulated write failure');
    _tasks.removeWhere((t) => t.id == id);
  }
}
