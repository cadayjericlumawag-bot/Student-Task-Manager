import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';

void main() {
  setUpAll(() async {
    // Initialize sqflite ffi for tests and use an in-memory database
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databasePathOverride = ':memory:';

    // Ensure schema is created
    final db = await DatabaseHelper.db();
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await DatabaseHelper.createTables(db);
  });

  setUp(() async {
    // Clean tables between tests
    final db = await DatabaseHelper.db();
    await db.delete('tasks');
    await db.delete('users');
  });

  tearDownAll(() {
    DatabaseHelper.databasePathOverride = null;
  });

  testWidgets('TasksScreen shows create task button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksScreen()));

    // Pump a couple frames to allow async init (DB read) to complete.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify we can find the floating action button to create tasks
    expect(
      find.byType(FloatingActionButton),
      findsOneWidget,
      reason: 'TasksScreen should have a FloatingActionButton to create tasks',
    );
  });
}
