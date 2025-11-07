import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    debugPrint('Setting up test database');
    // Disable runtime fetching of Google Fonts during tests to avoid async font loads
    try {
      // Prevent GoogleFonts from fetching fonts at runtime during tests.
      GoogleFonts.config.allowRuntimeFetching = false;
    } catch (e) {
      debugPrint('GoogleFonts config not applied: $e');
    }
    await initTestDb();
  });

  setUp(() async {
    debugPrint('Cleaning up test data');
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
  });

  tearDownAll(() {
    debugPrint('Tearing down test database');
    DatabaseHelper.databasePathOverride = null;
  });

  group('TaskFormSheet', () {
    Widget createWidget({
      required List<Map<String, dynamic>> testUsers,
      required VoidCallback onSaved,
    }) {
      return MaterialApp(
        home: Material(
          child: MediaQuery(
            data: const MediaQueryData(),
            child: TaskFormSheet(onSaved: onSaved, testUsers: testUsers),
          ),
        ),
      );
    }

    testWidgets('loads injected users correctly', (WidgetTester tester) async {
      debugPrint('Starting user loading test');
      debugPrint('Creating test user in database');
      final db = await DatabaseHelper.db();
      final userId = await db.insert('users', {
        'idNumber': 'TEST01',
        'fullName': 'Test User',
        'userName': 'test@example.com',
        'password': 'password123',
      });
      debugPrint('Test user created with ID: $userId');

      final testUsers = [
        {
          'id': userId,
          'idNumber': 'TEST01',
          'fullName': 'Test User',
          'userName': 'test@example.com',
          'password': 'password123',
        },
      ];

      final widget = createWidget(testUsers: testUsers, onSaved: () {});

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      debugPrint('Verifying user is displayed');
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty form', (
      WidgetTester tester,
    ) async {
      debugPrint('Starting form validation test');
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

      final widget = createWidget(testUsers: testUsers, onSaved: () {});

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      debugPrint('Tapping create button without filling form');
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      debugPrint('Verifying validation error is shown');
      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('creates task successfully', (WidgetTester tester) async {
      debugPrint('Starting task creation test');
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

      final widget = createWidget(
        testUsers: testUsers,
        onSaved: () {
          debugPrint('onSaved callback triggered');
          onSavedCalled = true;
        },
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      debugPrint('Entering task title');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Task Title',
      );
      await tester.pumpAndSettle();

      debugPrint('Tapping create button');
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      debugPrint('Verifying task creation');
      expect(onSavedCalled, isTrue);

      final tasks = await DatabaseHelper.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first['title'], equals('Test Task Title'));
      expect(tasks.first['assigneeId'], equals(userId));
      debugPrint('Task creation verified');
    });
  });
}
