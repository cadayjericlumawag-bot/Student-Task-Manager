import 'package:sqflite/sqflite.dart' as sql;
import '../sql_helper/database_helper.dart';

class NotificationDatabaseHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        data TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    """);
  }

  static Future<int> createNotification(
    Map<String, dynamic> notification,
  ) async {
    final db = await DatabaseHelper.db();
    return await db.insert(
      'notifications',
      notification,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    int? userId,
    bool unreadOnly = false,
    String? type,
  }) async {
    final db = await DatabaseHelper.db();

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'userId = ?';
      whereArgs.add(userId);
    }

    if (unreadOnly) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isRead = 0';
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type);
    }

    return await db.query(
      'notifications',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );
  }

  static Future<void> markAsRead(int id) async {
    final db = await DatabaseHelper.db();
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markAllAsRead({int? userId}) async {
    final db = await DatabaseHelper.db();
    if (userId != null) {
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } else {
      await db.update('notifications', {'isRead': 1});
    }
  }

  static Future<void> deleteNotification(int id) async {
    final db = await DatabaseHelper.db();
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteOldNotifications(int days) async {
    final db = await DatabaseHelper.db();
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    await db.delete(
      'notifications',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate],
    );
  }

  static Future<int> getUnreadCount({int? userId}) async {
    final db = await DatabaseHelper.db();
    final result = await db.query(
      'notifications',
      columns: ['COUNT(*) as count'],
      where: userId != null ? 'userId = ? AND isRead = 0' : 'isRead = 0',
      whereArgs: userId != null ? [userId] : null,
    );

    return result.first['count'] as int;
  }
}
