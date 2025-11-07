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

    // Create test user
    final db = await DatabaseHelper.db();
    await db.execute('DELETE FROM users');
    await db.execute('DELETE FROM tasks');
    debugPrint('Database cleaned');

    final userId = await DatabaseHelper.insertUser(
      'TEST01',
      'Test User',
      'test@example.com',
      'password123',
    );
    expect(userId, greaterThan(0));
    debugPrint('Test user created with ID: $userId');

    bool onSavedCalled = false;

    // Build a simplified TaskFormSheet
    await tester.pumpWidget(
      MaterialApp(
        home: TaskFormSheet(
          onSaved: () {
            onSavedCalled = true;
            debugPrint('onSaved callback triggered');
          },
        ),
      ),
    );
    debugPrint('Widget pumped');

    // Wait a short, finite time for initial async work to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    debugPrint('Initial frame pumped');

    // Verify form fields are present
    expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    expect(find.text('CREATE TASK'), findsOneWidget);
    debugPrint('Form elements found');

    // Enter minimal valid data
    await tester.enterText(find.byType(TextFormField).first, 'Test Task Title');
    debugPrint('Entered task title');

    await tester.pump();
    debugPrint('Frame updated after text entry');

    // Submit the form
    await tester.tap(find.text('CREATE TASK'));
    debugPrint('Tapped submit button');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    debugPrint('Final frame pumped');

    // Verify callback was triggered
    expect(onSavedCalled, isTrue);
    debugPrint('Test completed');
  });
}
