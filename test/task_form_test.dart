import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
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

  testWidgets('Basic task form renders and saves', (tester) async {
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
        home: Scaffold(
          body: TaskFormSheet(
            onSaved: () {
              onSavedCalled = true;
              debugPrint('onSaved callback triggered');
            },
          ),
        ),
      ),
    );

    // Initial build
    await tester.pump();
    debugPrint('Widget pumped');

    // Required fields: title, assignee, priority
    await tester.enterText(find.byType(TextFormField).first, 'Test Task Title');
    debugPrint('Entered title');

    await tester.pump();

    // Select first user in dropdown (our test user)
    final assigneeDropdown = find.byType(DropdownButtonFormField<int>).first;
    await tester.tap(assigneeDropdown);
    await tester.pump();

    // Select first item (should be our test user)
    await tester.tap(find.text('Test User').first);
    await tester.pump();
    debugPrint('Selected assignee');

    // Submit the form
    final createButton = find.text('CREATE TASK');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    debugPrint('Tapped create button');

    // Verify callback triggered
    expect(
      onSavedCalled,
      isTrue,
      reason: 'onSaved should be called after creating task',
    );
    debugPrint('Callback verified');

    // Verify task was saved to DB
    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], equals('Test Task Title'));
    debugPrint('Database write verified');
  });
}
