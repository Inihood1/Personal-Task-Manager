import 'package:hive_ce/hive.dart';

import '../models/task_model.dart';

/// Thin wrapper around the Hive [Box] that stores tasks.
///
/// It deals purely in [TaskModel] and exposes just the CRUD primitives the
/// repository needs. There is a single concrete implementation (Hive), so no
/// interface is introduced here — that would be abstraction for its own sake.
class TaskLocalDataSource {
  const TaskLocalDataSource(this._box);

  final Box<TaskModel> _box;

  /// Returns every stored model. Ordering is left to the caller.
  List<TaskModel> getAll() => _box.values.toList(growable: false);

  /// Inserts or overwrites a model, keyed by its id.
  Future<void> put(TaskModel model) => _box.put(model.id, model);

  /// Removes the model with the given [id]. A no-op if absent.
  Future<void> delete(String id) => _box.delete(id);
}
