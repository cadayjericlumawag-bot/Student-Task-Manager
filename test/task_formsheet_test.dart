import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    // Disable GoogleFonts for testing to avoid network requests
    GoogleFonts.config.allowRuntimeFetching = false;

    // Initialize test database
    await initTestDb();
  });

  setUp(() async {
    // Clean database before each test
    final db = await DatabaseHelper.db();
    await db.delete('tasks');
    await db.delete('users');
  });

  tearDownAll(() {
    // Reset database path override
    DatabaseHelper.databasePathOverride = null;
  });

  group('TaskFormSheet Widget Tests', () {
    testWidgets('creates task with valid input', (WidgetTester tester) async {
      // Create a test user
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

      bool onSavedCalled = false;

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TaskFormSheet(
              onSaved: () => onSavedCalled = true,
              testUsers: testUsers,
            ),
          ),
        ),
      );

      // Initial pump to load users
      await tester.pumpAndSettle();

      // Enter task title
      await tester.enterText(find.byType(TextFormField).first, 'Test Task');
      await tester.pump();

      // Submit form
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      // Verify task was created
      expect(onSavedCalled, isTrue);

      final tasks = await DatabaseHelper.getTasks();
      expect(tasks.length, equals(1));
      expect(tasks.first['title'], equals('Test Task'));
      expect(tasks.first['assigneeId'], equals(userId));
    });

    testWidgets('shows validation error for empty title', (
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
          home: Material(
            child: TaskFormSheet(onSaved: () {}, testUsers: testUsers),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit without entering title
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      // Verify validation error is shown
      expect(find.text('Please enter a title'), findsOneWidget);
    });

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
          home: Material(
            child: TaskFormSheet(onSaved: () {}, testUsers: testUsers),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user is loaded in dropdown
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
