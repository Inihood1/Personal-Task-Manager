/// Domain-level exception raised when a task operation fails.
///
/// The data layer catches low-level storage errors (e.g. Hive failures) and
/// rethrows them as a [TaskException] so the rest of the app depends on a
/// single, storage-agnostic error type. The original error is preserved in
/// [cause] for logging/debugging.
class TaskException implements Exception {
  const TaskException(this.message, [this.cause]);

  /// Human-readable message safe to surface in the UI.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() =>
      'TaskException: $message${cause == null ? '' : ' (cause: $cause)'}';
}
