import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/tasks_screen.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mock minimal ThemeProvider to satisfy TasksScreen dependencies
class ThemeProvider with ChangeNotifier {
  final ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
}

void main() {
  setUpAll(() async {
    // Initialize FFI for desktop/test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databasePathOverride = ':memory:';

    // Initialize database schema
    final db = await DatabaseHelper.db();
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await DatabaseHelper.createTables(db);
  });

  setUp(() async {
    // Clean data before each test
    final db = await DatabaseHelper.db();
    await db.delete('users');
    await db.delete('tasks');
  });

  tearDownAll(() {
    DatabaseHelper.databasePathOverride = null;
  });

  group('TasksScreen Widget Tests', () {
    testWidgets('shows create task button and empty state', (tester) async {
      // Create test user
      await DatabaseHelper.insertUser(
        'TEST01',
        'Test User',
        'test@example.com',
        'password123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: const TasksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify UI elements
      expect(
        find.byType(FloatingActionButton),
        findsOneWidget,
        reason: 'Should show FAB to create tasks',
      );

      expect(
        find.text('No tasks found'),
        findsOneWidget,
        reason: 'Should show empty state message when no tasks exist',
      );
    });
  });
}
