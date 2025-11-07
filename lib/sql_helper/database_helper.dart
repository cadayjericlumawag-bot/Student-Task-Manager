import 'package:sqflite/sqflite.dart' as sql;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class DatabaseHelper {
  static String? _databasePathOverride;

  /// Override the database path, primarily for testing.
  /// Use ':memory:' for an in-memory database in tests.
  static set databasePathOverride(String? path) {
    _databasePathOverride = path;
  }

  static Future<List<Map<String, dynamic>>> getTasks({
    int? assigneeId,
    TaskStatus? status,
    String? ownerUid,
  }) async {
    final db = await DatabaseHelper.db();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (assigneeId != null) {
      whereClause = 'assigneeId = ?';
      whereArgs.add(assigneeId);
    }

    if (ownerUid != null) {
      whereClause += whereClause.isEmpty ? 'ownerUid = ?' : ' AND ownerUid = ?';
      whereArgs.add(ownerUid);
    }

    if (status != null) {
      whereClause += whereClause.isEmpty ? 'status = ?' : ' AND status = ?';
      whereArgs.add(status.index);
    }

    return await db.query(
      'tasks',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'dueDate ASC',
    );
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      _databasePathOverride ?? 'users.db',
      version: 3,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
      onUpgrade: (sql.Database database, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await database.execute("""
            CREATE TABLE tasks(
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              dueDate TEXT NOT NULL,
              status INTEGER NOT NULL,
              priority INTEGER NOT NULL,
              assigneeId INTEGER NOT NULL,
              createdById INTEGER NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT,
              FOREIGN KEY (assigneeId) REFERENCES users (id),
              FOREIGN KEY (createdById) REFERENCES users (id)
            )
          """);
        }
        // Add ownerUid column in version 3
        if (oldVersion < 3) {
          try {
            await database.execute(
              "ALTER TABLE tasks ADD COLUMN ownerUid TEXT",
            );
          } catch (e) {
            // Column may already exist on some databases; ignore errors
            debugPrint('Error adding ownerUid column: $e');
          }
        }
      },
    );
  }

  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        idNumber TEXT,
        fullName TEXT,
        userName TEXT,
        password TEXT
      )
    """);

    await database.execute("""
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        data TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    """);

    await database.execute("""
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        status INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        assigneeId INTEGER NOT NULL,
        createdById INTEGER NOT NULL,
        ownerUid TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (assigneeId) REFERENCES users (id),
        FOREIGN KEY (createdById) REFERENCES users (id)
      )
    """);
  }

  //Validate if user exists
  static Future<List<Map<String, dynamic>>> checkIfUserExists(
    String idNumber,
    String fullName,
  ) async {
    final db = await DatabaseHelper.db();
    return await db.query(
      'users',
      where: 'idNumber = ? AND fullName = ?',
      whereArgs: [idNumber, fullName],
    );
  }

  //Insert data into users table
  static Future<int> insertUser(
    String idNumber,
    String fullName,
    String userName,
    String password,
  ) async {
    final db = await DatabaseHelper.db();
    final data = {
      'idNumber': idNumber,
      'fullName': fullName,
      'userName': userName,
      'password': password,
    };
    final id = await db.insert(
      'users',
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<List<Map<String, dynamic>>> loginUser(
    String userName,
    String password,
  ) async {
    final db = await DatabaseHelper.db();
    return db.query(
      'users',
      where: "userName = ? AND password = ?",
      whereArgs: [userName, password],
    );
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // First check Firebase auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final db = await DatabaseHelper.db();
        // Try to find user by email
        final List<Map<String, dynamic>> users = await db.query(
          'users',
          where: 'userName = ?',
          whereArgs: [firebaseUser.email],
          limit: 1,
        );
        if (users.isNotEmpty) {
          return users.first;
        }
        // If we have a Firebase user but no local user row, create one so
        // tasks can be created/attributed to a local user id while still
        // recording the firebase UID in the task.ownerUid field.
        try {
          final fullName =
              firebaseUser.displayName ?? firebaseUser.email ?? 'Firebase User';
          final userName = firebaseUser.email ?? 'firebase:${firebaseUser.uid}';
          // Insert a local user record and return it
          final id = await db.insert('users', {
            'idNumber': null,
            'fullName': fullName,
            'userName': userName,
            'password': null,
          }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
          final List<Map<String, dynamic>> newUser = await db.query(
            'users',
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );
          if (newUser.isNotEmpty) return newUser.first;
        } catch (e) {
          debugPrint('Error creating local user for firebase user: $e');
        }
      }
      // If no Firebase user or no matching local user, return null
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUsers({
    bool activeOnly = true,
  }) async {
    final db = await DatabaseHelper.db();
    return db.query(
      'users',
      orderBy: 'fullName ASC',
      where: activeOnly ? 'isDeleted = 0 OR isDeleted IS NULL' : null,
    );
  }

  static Future<int> updateUser(
    int id,
    String idNumber,
    String fullName,
    String userName,
    String password,
  ) async {
    final db = await DatabaseHelper.db();

    final data = {
      'idNumber': idNumber,
      'fullName': fullName,
      'userName': userName,
      'password': password,
    };

    final result = await db.update(
      'users',
      data,
      where: "id = ?",
      whereArgs: [id],
    );
    return result;
  }

  static Future<void> deleteUser(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete("users", where: 'id = ?', whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Task-related operations
  static Future<int> createTask(Map<String, dynamic> task) async {
    final db = await DatabaseHelper.db();
    try {
      debugPrint('DatabaseHelper.createTask: inserting task ${task['title']}');
      final id = await db.insert(
        'tasks',
        task,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      debugPrint('DatabaseHelper.createTask: insert completed id=$id');
      return id;
    } catch (e) {
      debugPrint('DatabaseHelper.createTask: ERROR $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTasksByDueDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.db();
    return await db.query(
      'tasks',
      where: 'dueDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'dueDate ASC',
    );
  }

  static Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await DatabaseHelper.db();
    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateTaskStatus(int id, TaskStatus status) async {
    final db = await DatabaseHelper.db();
    return await db.update(
      'tasks',
      {'status': status.index, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteTask(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting a task: $err");
    }
  }

  static Future<Map<String, dynamic>> getTaskStats({
    String? ownerUid,
    int? assigneeId,
  }) async {
    final db = await DatabaseHelper.db();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Build WHERE clause when filtering by ownerUid or assigneeId
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (ownerUid != null) {
      whereClause = ' WHERE ownerUid = ?';
      whereArgs = [ownerUid];
    } else if (assigneeId != null) {
      whereClause = ' WHERE assigneeId = ?';
      whereArgs = [assigneeId];
    }

    final totalTasks =
        sql.Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM tasks$whereClause',
            whereArgs.isEmpty ? null : whereArgs,
          ),
        ) ??
        0;

    final tasksToday =
        sql.Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM tasks$whereClause${whereClause.isEmpty ? ' WHERE dueDate BETWEEN ? AND ?' : ' AND dueDate BETWEEN ? AND ?'}',
            (whereArgs + [today.toIso8601String(), tomorrow.toIso8601String()]),
          ),
        ) ??
        0;

    final overdueTasks =
        sql.Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM tasks$whereClause${whereClause.isEmpty ? ' WHERE datetime(dueDate) < datetime(?) AND status = ?' : ' AND datetime(dueDate) < datetime(?) AND status = ?'}',
            (whereArgs +
                [DateTime.now().toIso8601String(), TaskStatus.todo.index]),
          ),
        ) ??
        0;

    final completedTasks =
        sql.Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM tasks$whereClause${whereClause.isEmpty ? ' WHERE status = ?' : ' AND status = ?'}',
            (whereArgs + [TaskStatus.completed.index]),
          ),
        ) ??
        0;

    return {
      'total': totalTasks,
      'today': tasksToday,
      'overdue': overdueTasks,
      'completed': completedTasks,
    };
  }

  /// Migrate existing tasks that don't have an ownerUid set.
  ///
  /// Strategy:
  /// - For each user in `users`, determine a best-effort UID:
  ///   - If `userName` looks like an email, use it as ownerUid.
  ///   - Otherwise use the sentinel 'local:ID' where ID is the user's local id.
  /// - Update tasks where ownerUid IS NULL and (createdById = user.id OR assigneeId = user.id)
  /// Returns the number of rows updated.
  static Future<int> migrateSetOwnerUidFromUsers() async {
    final db = await DatabaseHelper.db();
    int updatedTotal = 0;

    final users = await db.query('users');
    for (final user in users) {
      final int uid = user['id'] as int;
      final String? userName = user['userName'] as String?;
      final String ownerUid = (userName != null && userName.contains('@'))
          ? userName
          : 'local:$uid';

      final count = await db.rawUpdate(
        'UPDATE tasks SET ownerUid = ? WHERE ownerUid IS NULL AND (createdById = ? OR assigneeId = ?)',
        [ownerUid, uid, uid],
      );

      updatedTotal += count;
    }

    // For any remaining tasks without ownerUid, mark them as local:unknown
    final remaining = await db.rawUpdate(
      "UPDATE tasks SET ownerUid = 'local:unknown' WHERE ownerUid IS NULL",
    );
    updatedTotal += remaining;

    return updatedTotal;
  }

  /// Map local user IDs to real Firebase UIDs.
  ///
  /// `mapping` is a map from local user id (int) -> firebaseUid (String).
  /// This will update tasks where ownerUid is 'local:ID' (the local sentinel) and replace it with the provided firebase UID.
  /// Returns number of rows updated.
  static Future<int> migrateMapLocalToFirebase(Map<int, String> mapping) async {
    final db = await DatabaseHelper.db();
    int totalUpdated = 0;
    for (final entry in mapping.entries) {
      final localId = entry.key;
      final firebaseUid = entry.value;
      // Update tasks that were assigned the local:<id> sentinel
      final count = await db.rawUpdate(
        'UPDATE tasks SET ownerUid = ? WHERE ownerUid = ?',
        [firebaseUid, 'local:$localId'],
      );
      totalUpdated += count;
    }
    return totalUpdated;
  }

  // Notification-related operations
  static Future<int> createNotification({
    required String title,
    required String message,
    required int type,
    required DateTime timestamp,
    String? data,
    int? userId,
  }) async {
    final db = await DatabaseHelper.db();
    final notification = {
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': 0,
      'data': data,
      'userId': userId,
    };

    return await db.insert(
      'notifications',
      notification,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    int? userId,
    bool unreadOnly = false,
  }) async {
    final db = await DatabaseHelper.db();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause = 'userId = ?';
      whereArgs.add(userId);
    }

    if (unreadOnly) {
      whereClause += whereClause.isEmpty ? 'isRead = 0' : ' AND isRead = 0';
    }

    return await db.query(
      'notifications',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );
  }

  static Future<int> markNotificationAsRead(int id) async {
    final db = await DatabaseHelper.db();
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> markAllNotificationsAsRead({int? userId}) async {
    final db = await DatabaseHelper.db();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause = 'userId = ?';
      whereArgs.add(userId);
    }

    return await db.update(
      'notifications',
      {'isRead': 1},
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
  }

  static Future<void> deleteNotification(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting a notification: $err");
    }
  }

  static Future<void> deleteAllNotifications({int? userId}) async {
    final db = await DatabaseHelper.db();
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause = 'userId = ?';
        whereArgs.add(userId);
      }

      await db.delete(
        'notifications',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );
    } catch (err) {
      debugPrint("Something went wrong when deleting notifications: $err");
    }
  }

  static Future<int> getUnreadNotificationCount({int? userId}) async {
    final db = await DatabaseHelper.db();
    String whereClause = 'isRead = 0';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += ' AND userId = ?';
      whereArgs.add(userId);
    }

    final result = await db.query(
      'notifications',
      columns: ['COUNT(*) as count'],
      where: whereClause,
      whereArgs: whereArgs,
    );

    return sql.Sqflite.firstIntValue(result) ?? 0;
  }
}
