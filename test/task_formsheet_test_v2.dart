import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDb();
  });

  setUp(() async {
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
  });

  tearDownAll(() {
    DatabaseHelper.databasePathOverride = null;
  });

  group('TaskFormSheet', () {
    // Test 1: Loading users
    testWidgets('loads injected users correctly', (WidgetTester tester) async {
      final userId = await createTestUser();
      final testUsers = [
        {
          'id': userId,
          'idNumber': 'TEST01',
          'fullName': 'Test User',
          'userName': 'test@example.com',
          'password': 'password123',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskFormSheet(onSaved: () {}, testUsers: testUsers),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
    });

    // Test 2: Form validation
    testWidgets('shows validation errors for empty form', (
      WidgetTester tester,
    ) async {
      final userId = await createTestUser();
      final testUsers = [
        {
          'id': userId,
          'idNumber': 'TEST01',
          'fullName': 'Test User',
          'userName': 'test@example.com',
          'password': 'password123',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskFormSheet(onSaved: () {}, testUsers: testUsers),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    // Test 3: Task creation
    testWidgets('creates task successfully', (WidgetTester tester) async {
      final userId = await createTestUser();
      final testUsers = [
        {
          'id': userId,
          'idNumber': 'TEST01',
          'fullName': 'Test User',
          'userName': 'test@example.com',
          'password': 'password123',
        },
      ];

      var onSavedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskFormSheet(
              onSaved: () => onSavedCalled = true,
              testUsers: testUsers,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Task Title',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      expect(onSavedCalled, isTrue);

      final tasks = await DatabaseHelper.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first['title'], equals('Test Task Title'));
      expect(tasks.first['assigneeId'], equals(userId));
    });
  });
}
