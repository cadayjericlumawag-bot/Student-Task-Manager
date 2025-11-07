import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/task_form_test_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late TaskFormTestHelper helper;

  setUpAll(() async {
    debugPrint('Setting up test environment');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databasePathOverride = ':memory:';

    final db = await DatabaseHelper.db();
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await DatabaseHelper.createTables(db);
  });

  setUp(() async {
    debugPrint('Setting up test');
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
  });

  tearDownAll(() {
    debugPrint('Cleaning up test environment');
    DatabaseHelper.databasePathOverride = null;
  });

  testWidgets('TaskFormSheet - Create task with valid data', (tester) async {
    debugPrint('Starting task creation test');

    // Initialize helper
    helper = TaskFormTestHelper(tester);

    // Create test user
    await helper.createTestUser();
    expect(helper.testUserId, greaterThan(0));
    debugPrint('Created test user with ID: ${helper.testUserId}');

    // Build and initialize widget
    await helper.pumpTaskForm();
    debugPrint('Form initialized');

    // Enter title
    await helper.enterTitle('Test Task Title');
    debugPrint('Title entered');

    // Submit form
    await helper.submitForm();
    debugPrint('Form submitted');

    // Verify callback and DB
    expect(helper.onSavedCalled, isTrue);
    final task = await helper.getCreatedTask();
    expect(task, isNotNull);
    expect(task!['title'], equals('Test Task Title'));
    debugPrint('Task verified in database');
  });

  testWidgets('TaskFormSheet - Shows validation errors', (tester) async {
    debugPrint('Starting validation test');

    // Initialize helper
    helper = TaskFormTestHelper(tester);
    await helper.createTestUser();
    await helper.pumpTaskForm();
    debugPrint('Form initialized');

    // Submit without title
    await helper.submitForm();
    debugPrint('Attempted submit without title');

    // Verify validation error
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(helper.onSavedCalled, isFalse);
    final task = await helper.getCreatedTask();
    expect(task, isNull);
    debugPrint('Validation verified');
  });
}
