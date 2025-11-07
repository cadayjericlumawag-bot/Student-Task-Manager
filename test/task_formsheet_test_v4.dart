import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await initTestDb();
  });

  tearDown(() {
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

    // Build widget
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

    // Wait for widget to settle
    await tester.pump(const Duration(seconds: 1));

    // Verify the widget is in the expected state
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('CREATE TASK'), findsOneWidget);

    // Enter text in title field
    final titleField = find.byType(TextFormField).first;
    await tester.enterText(titleField, 'Test Task Title');
    await tester.pump();

    // Wait for any animations
    await tester.pump(const Duration(seconds: 1));

    // Tap create button
    final createButton = find.text('CREATE TASK');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    // Wait for database operation
    await tester.pump(const Duration(seconds: 2));

    // Verify task was created
    expect(onSavedCalled, isTrue);

    final tasks = await DatabaseHelper.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first['title'], equals('Test Task Title'));
  });
}
