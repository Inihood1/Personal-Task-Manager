import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_task_manager/presentation/providers/task_providers.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  late InMemoryTaskRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
      // Disable Riverpod 3's automatic error-retry so the error-path test is
      // deterministic (no background rebuilds against a disposed container).
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => repository = InMemoryTaskRepository());

  test('build loads existing tasks from the repository', () async {
    repository.seed([sampleTask(id: '1'), sampleTask(id: '2')]);
    final container = makeContainer();

    final tasks = await container.read(taskListProvider.future);

    expect(tasks, hasLength(2));
  });

  test('addTask creates and persists a new task', () async {
    final container = makeContainer();
    await container.read(taskListProvider.future);

    await container
        .read(taskListProvider.notifier)
        .addTask(title: 'New task', description: 'details');

    final tasks = container.read(taskListProvider).value!;
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'New task');
    expect(tasks.single.isCompleted, isFalse);
  });

  test('editTask updates title and description', () async {
    repository.seed([sampleTask(id: '1', title: 'Old')]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    await container.read(taskListProvider.notifier).editTask(
          id: '1',
          title: 'New',
          description: 'Changed',
        );

    final task = container.read(taskListProvider).value!.single;
    expect(task.title, 'New');
    expect(task.description, 'Changed');
  });

  test('toggleComplete flips completion status', () async {
    repository.seed([sampleTask(id: '1', isCompleted: false)]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    await container.read(taskListProvider.notifier).toggleComplete('1');
    expect(container.read(taskListProvider).value!.single.isCompleted, isTrue);

    await container.read(taskListProvider.notifier).toggleComplete('1');
    expect(container.read(taskListProvider).value!.single.isCompleted, isFalse);
  });

  test('deleteTask removes the task', () async {
    repository.seed([sampleTask(id: '1'), sampleTask(id: '2')]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    await container.read(taskListProvider.notifier).deleteTask('1');

    final ids = container.read(taskListProvider).value!.map((t) => t.id);
    expect(ids, ['2']);
  });

  test('restoreTask re-inserts a previously deleted task (undo)', () async {
    final task = sampleTask(id: '1', title: 'Restore me');
    repository.seed([task]);
    final container = makeContainer();
    await container.read(taskListProvider.future);

    await container.read(taskListProvider.notifier).deleteTask('1');
    expect(container.read(taskListProvider).value, isEmpty);

    await container.read(taskListProvider.notifier).restoreTask(task);
    expect(container.read(taskListProvider).value!.single, equals(task));
  });

  test('surfaces an error state when the repository fails', () async {
    repository.failOnGet = true;
    final container = makeContainer();

    await expectLater(
      container.read(taskListProvider.future),
      throwsA(anything),
    );
    expect(container.read(taskListProvider).hasError, isTrue);
  });
}
