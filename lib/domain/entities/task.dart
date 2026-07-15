import 'package:equatable/equatable.dart';

/// A single task in the user's list.
///
/// This is a **pure domain entity**: immutable, framework-free, and with no
/// persistence annotations. The data layer maps it to/from a Hive-aware model
/// ([TaskModel]) so storage concerns never leak into business logic or the UI.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Stable unique identifier (also used as the storage key).
  final String id;

  final String title;

  final String description;

  final bool isCompleted;

  /// When the task was first created. Never changes.
  final DateTime createdAt;

  /// When the task was last modified.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// [id] and [createdAt] are intentionally immutable — a task keeps its
  /// identity and creation time for its whole lifetime.
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, description, isCompleted, createdAt, updatedAt];
}
