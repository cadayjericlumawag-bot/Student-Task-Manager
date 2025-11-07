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

  tearDownAll(() {
    debugPrint('Cleaning up test environment');
    DatabaseHelper.databasePathOverride = null;
  });

  setUp(() async {
    // Clean DB before each test
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
    debugPrint('Database cleaned for new test');
  });

  Future<void> buildTestWidget({
    required WidgetTester tester,
    required VoidCallback onSaved,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: TaskFormSheet(onSaved: onSaved)),
      ),
    );

    // Wait for widget to build and load initial data
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('TaskFormSheet - Create task with valid data', (tester) async {
    debugPrint('Starting task creation test');

    // 1. Create test user
    final userId = await createTestUser();
    expect(userId, greaterThan(0), reason: 'Test user should be created');
    debugPrint('Created test user with ID: $userId');

    // 2. Build form and track saves
    var onSavedCalled = false;
    await buildTestWidget(
      tester: tester,
      onSaved: () {
        debugPrint('onSaved callback triggered');
        onSavedCalled = true;
      },
    );
    debugPrint('Widget built and initialized');

    // 3. Enter required title
    await tester.enterText(find.byType(TextFormField).first, 'Test Task Title');
    await tester.pump();
    debugPrint('Entered title');

    // 4. Submit form (defaults should be valid with test user)
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    debugPrint('Submitted form');

    // 5. Verify task was saved
    expect(
      onSavedCalled,
      isTrue,
      reason: 'onSaved callback should be triggered',
    );

    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1), reason: 'One task should exist');
    expect(
      tasks.first['title'],
      'Test Task Title',
      reason: 'Task title should match input',
    );
    debugPrint('Task verified in database');
  });

  testWidgets('TaskFormSheet - Shows validation errors', (tester) async {
    debugPrint('Starting validation test');

    // 1. Setup
    await createTestUser();
    var onSavedCalled = false;

    // 2. Build widget
    await buildTestWidget(tester: tester, onSaved: () => onSavedCalled = true);
    debugPrint('Widget built and initialized');

    // 3. Try to submit without title
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 4. Verify validation error shows
    expect(
      find.text('Please enter a title'),
      findsOneWidget,
      reason: 'Should show title validation error',
    );
    expect(onSavedCalled, isFalse, reason: 'Should not save with invalid data');
    debugPrint('Validation errors verified');
  });
}
