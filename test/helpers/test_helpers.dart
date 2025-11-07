import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myapp/sql_helper/database_helper.dart';

/// Initialize the test database with a clean in-memory SQLite instance
Future<void> initTestDb() async {
  // Ensure Flutter bindings are initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Use in-memory database for testing
  DatabaseHelper.databasePathOverride = ':memory:';

  try {
    // Create fresh schema
    final db = await DatabaseHelper.db();
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await DatabaseHelper.createTables(db);
  } catch (e) {
    debugPrint('Error initializing test database: $e');
    rethrow;
  }
}

/// Create a test user and return their ID
Future<int> createTestUser() async {
  try {
    return await DatabaseHelper.insertUser(
      'TEST01',
      'Test User',
      'test@example.com',
      'password123',
    );
  } catch (e) {
    debugPrint('Error creating test user: $e');
    rethrow;
  }
}

/// Helper to verify database state
Future<void> verifyDatabaseEmpty() async {
  final db = await DatabaseHelper.db();
  final users = await db.query('users');
  final tasks = await db.query('tasks');

  assert(users.isEmpty, 'Users table should be empty');
  assert(tasks.isEmpty, 'Tasks table should be empty');
}
