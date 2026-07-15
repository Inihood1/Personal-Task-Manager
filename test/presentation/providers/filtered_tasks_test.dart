import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_task_manager/presentation/providers/task_providers.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  late InMemoryTaskRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => repository = InMemoryTaskRepository());

  test('matches title or description, case-insensitively', () async {
    repository.seed([
      sampleTask(id: '1', title: 'Buy milk'),
      sampleTask(id: '2', title: 'Call plumber', description: 'about the leak'),
      sampleTask(id: '3', title: 'Read book'),
    ]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    container.read(searchQueryProvider.notifier).update('LEAK');

    final filtered = container.read(filteredTasksProvider).value!;
    expect(filtered.map((t) => t.id), ['2']);
  });

  test('empty query returns all tasks', () async {
    repository.seed([sampleTask(id: '1'), sampleTask(id: '2')]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    final filtered = container.read(filteredTasksProvider).value!;
    expect(filtered, hasLength(2));
  });

  test('sorts active tasks before completed, newest updated first', () async {
    repository.seed([
      sampleTask(id: 'done', isCompleted: true, updatedAt: DateTime(2026, 7, 10)),
      sampleTask(id: 'older', updatedAt: DateTime(2026, 7, 1)),
      sampleTask(id: 'newer', updatedAt: DateTime(2026, 7, 5)),
    ]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    final filtered = container.read(filteredTasksProvider).value!;
    expect(filtered.map((t) => t.id), ['newer', 'older', 'done']);
  });
}
