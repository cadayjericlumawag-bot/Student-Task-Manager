import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/task_form_sheet.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initTestDb();
  });

  setUp(() async {
    final db = await DatabaseHelper.db();
    await db.delete('tasks');
    await db.delete('users');
  });

  tearDownAll(() {
    DatabaseHelper.databasePathOverride = null;
  });

  testWidgets('TaskFormSheet creates task with injected users', (tester) async {
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskFormSheet(
            onSaved: () {
              onSavedCalled = true;
            },
            testUsers: testUsers,
          ),
        ),
      ),
    );

    // Wait for widget to initialize and load users
    await tester.pumpAndSettle();

    // Verify the assignee dropdown is populated
    expect(find.text('Test User'), findsOneWidget);

    // Enter task title and submit
    await tester.enterText(find.byType(TextFormField).first, 'Test Task Title');
    await tester.pumpAndSettle();

    await tester.tap(find.text('CREATE TASK'));
    await tester.pumpAndSettle();

    // Verify task was created
    expect(onSavedCalled, isTrue);
    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], equals('Test Task Title'));
    expect(tasks.first['assigneeId'], equals(userId));
  });
}
