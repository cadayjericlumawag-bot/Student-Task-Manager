import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_helpers.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:myapp/models/task.dart';

void main() {
  setUp(() async {
    await initTestDb();
  });

  tearDown(() async {
    DatabaseHelper.databasePathOverride = null;
  });

  test(
    'migrateSetOwnerUidFromUsers populates ownerUid and stats filter by ownerUid',
    () async {
      // create a test user
      final userId = await createTestUser();

      // create a task without ownerUid
      final task = Task(
        title: 'Test Task',
        description: 'A task for testing',
        dueDate: DateTime.now().add(Duration(days: 1)),
        assigneeId: userId,
        createdById: userId,
      );

      await DatabaseHelper.createTask(task.toMap());

      // Ensure task exists and has null ownerUid
      final tasksBefore = await DatabaseHelper.getTasks(assigneeId: userId);
      expect(tasksBefore.length, 1);
      expect(tasksBefore.first['ownerUid'], isNull);

      // Run migration
      final updated = await DatabaseHelper.migrateSetOwnerUidFromUsers();
      expect(updated, greaterThanOrEqualTo(1));

      // After migration, task should have ownerUid set to the user's userName (email in test helpers)
      final tasksAfter = await DatabaseHelper.getTasks(assigneeId: userId);
      expect(tasksAfter.length, 1);
      expect(tasksAfter.first['ownerUid'], isNotNull);

      // Stats by ownerUid should reflect the task
      final ownerUid = tasksAfter.first['ownerUid'] as String;
      final stats = await DatabaseHelper.getTaskStats(ownerUid: ownerUid);
      expect(stats['total'], 1);
    },
  );

  test('getTaskStats and getTasks filter by assigneeId', () async {
    final userId = await createTestUser();

    final task1 = Task(
      title: 'Task 1',
      description: 'First',
      dueDate: DateTime.now().add(Duration(days: 1)),
      assigneeId: userId,
      createdById: userId,
      status: TaskStatus.todo,
    );
    final task2 = Task(
      title: 'Task 2',
      description: 'Second',
      dueDate: DateTime.now().subtract(Duration(days: 1)),
      assigneeId: userId,
      createdById: userId,
      status: TaskStatus.completed,
    );

    await DatabaseHelper.createTask(task1.toMap());
    await DatabaseHelper.createTask(task2.toMap());

    final tasks = await DatabaseHelper.getTasks(assigneeId: userId);
    expect(tasks.length, 2);

    final stats = await DatabaseHelper.getTaskStats(assigneeId: userId);
    expect(stats['total'], 2);
    expect(stats['completed'], 1);
  });
}
