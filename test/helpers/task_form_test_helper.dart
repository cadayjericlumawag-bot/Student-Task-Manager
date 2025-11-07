import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myapp/widgets/task_form_sheet.dart';
import 'package:myapp/sql_helper/database_helper.dart';

/// Helper class to manage test widget lifecycle and state
class TaskFormTestHelper {
  final WidgetTester tester;
  bool onSavedCalled = false;
  late int testUserId;

  TaskFormTestHelper(this.tester);

  Future<void> setUp() async {
    // Initialize test environment
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      DatabaseHelper.databasePathOverride = ':memory:';
      debugPrint('TaskFormTestHelper: FFI DB initialized');

      // Create fresh schema
      final db = await DatabaseHelper.db();
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS users');
      await DatabaseHelper.createTables(db);
      debugPrint('TaskFormTestHelper: Schema created');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error in setUp: $e');
      rethrow;
    }
  }

  Future<void> tearDown() async {
    try {
      final db = await DatabaseHelper.db();
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.close();
      DatabaseHelper.databasePathOverride = null;
      debugPrint('TaskFormTestHelper: Test environment cleaned up');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error in tearDown: $e');
      rethrow;
    }
  }

  Future<void> createTestUser() async {
    testUserId = await DatabaseHelper.insertUser(
      'TEST01',
      'Test User',
      'test@example.com',
      'password123',
    );
  }

  Future<void> cleanDb() async {
    try {
      final db = await DatabaseHelper.db();
      await Future.wait([db.delete('users'), db.delete('tasks')]);
      debugPrint('TaskFormTestHelper: Database cleaned');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error cleaning database: $e');
      rethrow;
    }
  }

  Future<void> pumpTaskForm() async {
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TaskFormSheet(
              onSaved: () {
                onSavedCalled = true;
                debugPrint('TaskFormTestHelper: onSaved callback triggered');
              },
            ),
          ),
        ),
      );

      // Let widget fully initialize and settle
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      debugPrint('TaskFormTestHelper: Widget pumped and settled');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error pumping task form: $e');
      rethrow;
    }
  }

  Future<void> enterTitle(String title) async {
    try {
      await tester.enterText(find.byType(TextFormField).first, title);
      await tester.pump();
      debugPrint('TaskFormTestHelper: Entered title: $title');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error entering title: $e');
      rethrow;
    }
  }

  Future<void> submitForm() async {
    try {
      final createButton = find.text('CREATE TASK');
      expect(
        createButton,
        findsOneWidget,
        reason: 'CREATE TASK button not found',
      );

      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      debugPrint('TaskFormTestHelper: Form submitted');
    } catch (e) {
      debugPrint('TaskFormTestHelper: Error submitting form: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCreatedTask() async {
    final tasks = await DatabaseHelper.getTasks();
    return tasks.isEmpty ? null : tasks.first;
  }
}
