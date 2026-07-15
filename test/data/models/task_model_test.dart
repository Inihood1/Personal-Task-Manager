import 'package:flutter_test/flutter_test.dart';
import 'package:personal_task_manager/data/models/task_model.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  group('TaskModel mapping', () {
    test('fromEntity -> toEntity is a lossless round trip', () {
      final task = sampleTask(
        id: '42',
        title: 'Write tests',
        description: 'Cover every layer',
        isCompleted: true,
        createdAt: DateTime(2026, 1, 2, 3, 4),
        updatedAt: DateTime(2026, 5, 6, 7, 8),
      );

      final roundTripped = TaskModel.fromEntity(task).toEntity();

      // Equatable equality checks every field at once.
      expect(roundTripped, equals(task));
    });
  });
}
