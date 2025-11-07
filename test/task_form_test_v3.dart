import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:myapp/models/task.dart';
import 'helpers/test_helpers.dart';

class MockContext extends StatelessWidget {
  final Widget child;

  const MockContext({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }
}

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

  testWidgets('TaskFormSheet - Create task with valid data', (tester) async {
    debugPrint('Starting task creation test');

    // 1. Create a test user first
    final userId = await createTestUser();
    expect(userId, greaterThan(0), reason: 'Test user should be created');
    debugPrint('Created test user with ID: $userId');

    bool onSavedCalled = false;

    // 2. Build the form with required context
    await tester.pumpWidget(
      MockContext(
        child: TaskFormSheet(
          onSaved: () {
            debugPrint('onSaved callback triggered');
            onSavedCalled = true;
          },
        ),
      ),
    );
    debugPrint('Widget built');

    // 3. Let it load users
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    debugPrint('Initial loading complete');

    // 4. Enter the title (required)
    await tester.enterText(
      find.byType(TextFormField).first,
      'Integration Test Task',
    );
    await tester.pump();
    debugPrint('Title entered');

    // 5. Verify we can find form elements
    expect(find.text('Integration Test Task'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<TaskPriority>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    debugPrint('Found all form elements');

    // 6. Submit the form (defaults should be valid)
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    debugPrint('Form submitted');

    // 7. Verify the task was saved
    expect(
      onSavedCalled,
      isTrue,
      reason: 'onSaved callback should be triggered',
    );

    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1), reason: 'One task should be saved');
    expect(
      tasks.first['title'],
      'Integration Test Task',
      reason: 'Task title should match input',
    );
    debugPrint('Task verified in database');
  });

  testWidgets('TaskFormSheet - Shows validation errors', (tester) async {
    debugPrint('Starting validation test');

    await createTestUser();
    bool onSavedCalled = false;

    await tester.pumpWidget(
      MockContext(child: TaskFormSheet(onSaved: () => onSavedCalled = true)),
    );
    debugPrint('Widget built');

    // Let it initialize
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Try to submit without a title
    await tester.tap(find.text('CREATE TASK'));
    await tester.pump();

    // Should show validation error
    expect(
      find.text('Please enter a title'),
      findsOneWidget,
      reason: 'Should show title validation error',
    );
    expect(onSavedCalled, isFalse, reason: 'Should not save with invalid data');
    debugPrint('Validation errors verified');
  });
}
