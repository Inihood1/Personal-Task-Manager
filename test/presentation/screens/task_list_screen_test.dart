import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_task_manager/presentation/providers/task_providers.dart';
import 'package:personal_task_manager/presentation/screens/task_list_screen.dart';

import '../../helpers/task_test_helpers.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    InMemoryTaskRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: TaskListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state when there are no tasks', (tester) async {
    await pumpScreen(tester, InMemoryTaskRepository());

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-field')), findsNothing);
  });

  testWidgets('renders the tasks in the list', (tester) async {
    await pumpScreen(
      tester,
      InMemoryTaskRepository([
        sampleTask(id: '1', title: 'Buy milk'),
        sampleTask(id: '2', title: 'Call plumber'),
      ]),
    );

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call plumber'), findsOneWidget);
  });

  testWidgets('filters the list as the user types in search', (tester) async {
    await pumpScreen(
      tester,
      InMemoryTaskRepository([
        sampleTask(id: '1', title: 'Buy milk'),
        sampleTask(id: '2', title: 'Call plumber'),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'milk',
    );
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Call plumber'), findsNothing);
  });

  testWidgets('shows a search-specific empty state for no matches',
      (tester) async {
    await pumpScreen(
      tester,
      InMemoryTaskRepository([sampleTask(id: '1', title: 'Buy milk')]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('search-field')),
      'zzz',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching tasks'), findsOneWidget);
  });

  testWidgets('swiping a task asks for confirmation before deleting',
      (tester) async {
    await pumpScreen(
      tester,
      InMemoryTaskRepository([sampleTask(id: '1', title: 'Buy milk')]),
    );

    await tester.drag(
      find.byKey(const ValueKey('task-1')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    // Confirmation dialog appears; the task is still present.
    expect(find.text('Delete task?'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Task removed and an undo snackbar is shown.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}
