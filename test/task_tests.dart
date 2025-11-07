import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'helpers/task_form_test_helper.dart';

void main() {
  late TaskFormTestHelper helper;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('Task tests: Global test environment initialized');
  });

  tearDownAll(() async {
    DatabaseHelper.databasePathOverride = null;
    debugPrint('Task tests: Global test environment cleaned up');
  });

  group('Database Operations', () {
    test('Can create and get users', () async {
      // Initialize database for this test
      DatabaseHelper.databasePathOverride = ':memory:';
      final db = await DatabaseHelper.db();
      await DatabaseHelper.createTables(db);

      final userId = await DatabaseHelper.insertUser(
        'TEST01',
        'Test User',
        'test@example.com',
        'password123',
      );
      expect(userId, greaterThan(0), reason: 'User ID should be positive');

      final users = await DatabaseHelper.getUsers();
      expect(users.length, 1, reason: 'Should have exactly one user');
      expect(
        users.first['username'],
        equals('TEST01'),
        reason: 'Username should match',
      );

      // Cleanup database
      await db.close();
      DatabaseHelper.databasePathOverride = null;
    });
  });
  group('Task Form Widget', () {
    testWidgets('Renders and accepts input', (WidgetTester tester) async {
      helper = TaskFormTestHelper(tester);
      await helper.setUp();

      // Create test user first
      await helper.createTestUser();
      debugPrint('Created test user with ID: ${helper.testUserId}');

      await helper.pumpTaskForm();
      debugPrint('Task form widget pumped');

      // Verify initial render
      expect(
        find.byType(TextFormField),
        findsAtLeastNWidgets(1),
        reason: 'Should find at least one text field',
      );
      expect(
        find.text('CREATE TASK'),
        findsOneWidget,
        reason: 'Should find create task button',
      );

      // Enter title and submit
      await helper.enterTitle('Test Task Title');
      await helper.submitForm();

      expect(
        helper.onSavedCalled,
        isTrue,
        reason: 'Form submission should trigger onSaved callback',
      );
      debugPrint('Task form test completed successfully');

      await helper.tearDown();
    });

    testWidgets('Validates required fields', (WidgetTester tester) async {
      helper = TaskFormTestHelper(tester);
      await helper.setUp();

      await helper.createTestUser();
      await helper.pumpTaskForm();

      // Try to submit without entering title
      await helper.submitForm();
      await tester.pumpAndSettle();

      expect(
        find.text('Title is required'),
        findsOneWidget,
        reason: 'Should show validation message for empty title',
      );
      expect(
        helper.onSavedCalled,
        isFalse,
        reason: 'Should not save form with validation errors',
      );
      debugPrint('Task form validation test completed successfully');

      await helper.tearDown();
    });
  });
}
