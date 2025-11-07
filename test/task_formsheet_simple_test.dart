import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
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

  testWidgets('TaskFormSheet basic test', (WidgetTester tester) async {
    final testUsers = [
      {
        'id': 1,
        'idNumber': 'TEST01',
        'fullName': 'Test User',
        'userName': 'test@example.com',
        'password': 'password123',
      },
    ];

    var onSavedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MediaQuery(
            data: const MediaQueryData(),
            child: TaskFormSheet(
              onSaved: () => onSavedCalled = true,
              testUsers: testUsers,
            ),
          ),
        ),
      ),
    );

    // Wait for the initial frame
    await tester.pump();

    // Verify assignee dropdown appears
    expect(find.text('Test User'), findsOneWidget);

    // Enter a title
    await tester.enterText(find.byType(TextFormField).first, 'Test Task Title');
    await tester.pump();

    // Tap create button
    await tester.tap(find.text('CREATE TASK'));
    await tester.pumpAndSettle();

    // Verify task was created
    expect(onSavedCalled, isTrue);
    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], equals('Test Task Title'));
  });
}
