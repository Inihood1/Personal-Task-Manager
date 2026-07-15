/// App-wide constant values.
///
/// Kept tiny and dependency-free so any layer can import it without pulling in
/// Flutter or storage concerns.
class AppConstants {
  const AppConstants._();

  /// Display name of the application.
  static const String appName = 'Personal Task Manager';

  /// Name of the Hive box that stores tasks.
  static const String tasksBoxName = 'tasks';

  /// Hive type id for the persisted task model. Must stay unique and stable
  /// for the lifetime of the stored data (see [TaskModelAdapter]).
  static const int taskTypeId = 0;

  /// Max length accepted for a task title.
  static const int maxTitleLength = 80;

  /// Max length accepted for a task description.
  static const int maxDescriptionLength = 500;
}
