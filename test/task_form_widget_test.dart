import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize sqflite ffi for desktop tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Use in-memory database for tests
    DatabaseHelper.databasePathOverride = ':memory:';

    // Ensure DB schema exists
    final db = await DatabaseHelper.db();
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await DatabaseHelper.createTables(db);
  });

  tearDownAll(() {
    // Clear the override after tests
    DatabaseHelper.databasePathOverride = null;
  });

  testWidgets('Create task via TaskFormSheet inserts into database', (
    tester,
  ) async {
    // Ensure a clean DB by opening and deleting any existing tables (use DatabaseHelper.db())
    final db = await DatabaseHelper.db();
    await db.execute('DELETE FROM users');
    await db.execute('DELETE FROM tasks');

    // Insert a user to be used as assignee
    final userId = await DatabaseHelper.insertUser(
      'ID123',
      'Test User',
      'testuser',
      'pass',
    );
    expect(userId, greaterThan(0));

    bool savedCalled = false;

    // Build the TaskFormSheet directly inside a MaterialApp so form fields and dropdowns work
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskFormSheet(
            onSaved: () {
              savedCalled = true;
            },
          ),
        ),
      ),
    );

    // Allow initial async work to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Fill title and description
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Widget Test Task',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Created via widget test',
    );

    // Wait briefly for dropdowns to settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the create button
    await tester.tap(find.textContaining('CREATE TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Callback should have been called
    expect(savedCalled, isTrue);

    // Verify task exists in DB
    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, isNotEmpty);
    final found = tasks.any((t) => t['title'] == 'Widget Test Task');
    expect(found, isTrue);
  });
}
