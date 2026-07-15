import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/models/task_model.dart';
import 'presentation/providers/task_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage before the app starts so the task list is available
  // synchronously to the repository.
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  final taskBox = await Hive.openBox<TaskModel>(AppConstants.tasksBoxName);

  runApp(
    ProviderScope(
      // Inject the opened box into the provider graph.
      overrides: [taskBoxProvider.overrideWithValue(taskBox)],
      child: const TaskManagerApp(),
    ),
  );
}
