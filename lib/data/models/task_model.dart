import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/task.dart';

/// Hive-persisted representation of a [Task].
///
/// This is the only place that knows about storage. It maps to/from the pure
/// [Task] domain entity so that Hive concerns (type ids, field indices) never
/// leak upwards.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromEntity(Task task) => TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      );

  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task toEntity() => Task(
        id: id,
        title: title,
        description: description,
        isCompleted: isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Hand-written Hive [TypeAdapter] for [TaskModel].
///
/// Written by hand (rather than generated with build_runner) so the project
/// clones-and-runs with zero build steps. The binary format matches what the
/// generator would emit.
///
/// IMPORTANT — schema stability rules:
///  * [typeId] must never change or be reused for another type.
///  * Field indices (the `writeByte(n)` values) are permanent. To add a field,
///    give it a brand-new index; never renumber or reuse a removed one.
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  int get typeId => AppConstants.taskTypeId;

  @override
  TaskModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(6) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}
