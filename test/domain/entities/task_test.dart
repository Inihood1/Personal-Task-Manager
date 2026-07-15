import 'package:flutter_test/flutter_test.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  group('Task', () {
    test('supports value equality', () {
      expect(sampleTask(id: '1'), equals(sampleTask(id: '1')));
      expect(sampleTask(id: '1'), isNot(equals(sampleTask(id: '2'))));
    });

    test('copyWith updates only the provided fields', () {
      final original = sampleTask(id: '1', title: 'A', isCompleted: false);
      final updated = original.copyWith(title: 'B', isCompleted: true);

      expect(updated.title, 'B');
      expect(updated.isCompleted, isTrue);
      expect(updated.description, original.description);
    });

    test('copyWith preserves immutable identity (id, createdAt)', () {
      final original = sampleTask(id: '1');
      final updated = original.copyWith(
        title: 'Changed',
        updatedAt: DateTime(2030),
      );

      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, DateTime(2030));
    });
  });
}
