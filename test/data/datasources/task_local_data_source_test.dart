import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:personal_task_manager/data/datasources/task_local_data_source.dart';
import 'package:personal_task_manager/data/models/task_model.dart';

import '../../helpers/task_test_helpers.dart';

/// Exercises the datasource against a REAL Hive box in a temp directory, which
/// also verifies the hand-written [TaskModelAdapter] serializes correctly.
void main() {
  late Directory tempDir;
  late Box<TaskModel> box;
  late TaskLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ptm_hive_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }
    box = await Hive.openBox<TaskModel>('tasks_test');
    dataSource = TaskLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('tasks_test');
    await tempDir.delete(recursive: true);
  });

  test('put then getAll survives serialization with all fields intact', () async {
    final model = TaskModel.fromEntity(
      sampleTask(
        id: '1',
        title: 'Buy milk',
        description: 'Semi-skimmed',
        isCompleted: true,
        createdAt: DateTime(2026, 7, 1, 9, 30),
        updatedAt: DateTime(2026, 7, 2, 10),
      ),
    );

    await dataSource.put(model);
    final all = dataSource.getAll();

    expect(all, hasLength(1));
    final stored = all.single;
    expect(stored.title, 'Buy milk');
    expect(stored.description, 'Semi-skimmed');
    expect(stored.isCompleted, isTrue);
    expect(stored.createdAt, DateTime(2026, 7, 1, 9, 30));
    expect(stored.updatedAt, DateTime(2026, 7, 2, 10));
  });

  test('put with an existing id overwrites rather than duplicates', () async {
    await dataSource.put(TaskModel.fromEntity(sampleTask(id: '1', title: 'v1')));
    await dataSource.put(TaskModel.fromEntity(sampleTask(id: '1', title: 'v2')));

    final all = dataSource.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'v2');
  });

  test('delete removes the stored model', () async {
    await dataSource.put(TaskModel.fromEntity(sampleTask(id: '1')));
    await dataSource.delete('1');

    expect(dataSource.getAll(), isEmpty);
  });
}
