import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:myapp/models/task.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    debugPrint('Setting up test environment');
    await initTestDb();
  });

  setUp(() async {
    // Clean DB before each test
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
    debugPrint('Database cleaned for new test');
  });

  tearDownAll(() {
    debugPrint('Cleaning up test environment');
    DatabaseHelper.databasePathOverride = null;
  });

  testWidgets('TaskFormSheet creates task with required fields', (
    tester,
  ) async {
    debugPrint('Test started');

    // Create test user and set up initial data
    final userId = await createTestUser();
    expect(userId, greaterThan(0));
    debugPrint('Test user created with ID: $userId');

    // Track onSaved callback
    bool onSavedCalled = false;

    // Build widget with necessary providers
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Material(
          child: TaskFormSheet(
            onSaved: () {
              onSavedCalled = true;
              debugPrint('onSaved callback triggered');
            },
          ),
        ),
      ),
    );
    debugPrint('Initial widget built');
    await tester.pump(); // Build frame

    // Skip the initial loading state
    await tester.pump(const Duration(milliseconds: 50));
    debugPrint('Skipped initial loading');

    // Fill required fields
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Test Task Title',
    );
    debugPrint('Title entered');
    await tester.pump();

    // Choose priority (medium is default)
    final priorityDropdown = find.widgetWithText(
      DropdownButtonFormField<TaskPriority>,
      'Priority',
    );
    await tester.tap(priorityDropdown);
    await tester.pump();
    await tester.tap(find.text('HIGH').last);
    await tester.pump();
    debugPrint('Priority selected');

    // Choose assignee (first user)
    final assigneeDropdown = find.widgetWithText(
      DropdownButtonFormField<int>,
      'Assignee',
    );
    await tester.tap(assigneeDropdown);
    await tester.pump();
    await tester.tap(find.text('Test User').last);
    await tester.pump();
    debugPrint('Assignee selected');

    // Submit form
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump(
      const Duration(milliseconds: 50),
    ); // Let save operation start
    debugPrint('Create button tapped');

    // Wait briefly for save to complete
    await tester.pump(const Duration(milliseconds: 50));

    // Verify callback was called
    expect(onSavedCalled, isTrue);
    debugPrint('Callback verified');

    // Verify task was saved with correct data
    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1));

    final savedTask = tasks.first;
    expect(savedTask['title'], equals('Test Task Title'));
    expect(savedTask['priority'], equals(TaskPriority.high.index));
    expect(savedTask['assigneeId'], equals(userId));
    debugPrint('Database write verified');
  });
}
