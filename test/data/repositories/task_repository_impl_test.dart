import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_task_manager/core/error/task_exception.dart';
import 'package:personal_task_manager/data/datasources/task_local_data_source.dart';
import 'package:personal_task_manager/data/models/task_model.dart';
import 'package:personal_task_manager/data/repositories/task_repository_impl.dart';
import 'package:personal_task_manager/domain/entities/task.dart';

import '../../helpers/task_test_helpers.dart';

class _MockDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late TaskRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(TaskModel.fromEntity(sampleTask(id: 'fallback')));
  });

  setUp(() {
    dataSource = _MockDataSource();
    repository = TaskRepositoryImpl(dataSource);
  });

  test('getTasks maps stored models to domain entities', () async {
    when(() => dataSource.getAll()).thenReturn([
      TaskModel.fromEntity(sampleTask(id: '1', title: 'Mapped')),
    ]);

    final tasks = await repository.getTasks();

    expect(tasks, hasLength(1));
    expect(tasks.single, isA<Task>());
    expect(tasks.single.title, 'Mapped');
  });

  test('addTask maps the entity to a model before persisting', () async {
    when(() => dataSource.put(any())).thenAnswer((_) async {});

    await repository.addTask(sampleTask(id: '7', title: 'Persist me'));

    final captured =
        verify(() => dataSource.put(captureAny())).captured.single as TaskModel;
    expect(captured.id, '7');
    expect(captured.title, 'Persist me');
  });

  test('deleteTask delegates to the datasource', () async {
    when(() => dataSource.delete(any())).thenAnswer((_) async {});

    await repository.deleteTask('9');

    verify(() => dataSource.delete('9')).called(1);
  });

  test('wraps low-level storage errors in a TaskException', () async {
    when(() => dataSource.getAll()).thenThrow(Exception('disk full'));

    expect(
      () => repository.getTasks(),
      throwsA(isA<TaskException>()),
    );
  });
}
