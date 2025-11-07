import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/task.dart';

void main() {
  test('Task toMap and fromMap roundtrip', () {
    final task = Task(
      id: 1,
      title: 'Test Task',
      description: 'A task for testing',
      dueDate: DateTime(2025, 11, 5),
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      assigneeId: 2,
      createdById: 1,
    );

    final map = task.toMap();
    final restored = Task.fromMap(map);

    expect(restored.id, task.id);
    expect(restored.title, task.title);
    expect(restored.description, task.description);
    expect(restored.dueDate, task.dueDate);
    expect(restored.status, task.status);
    expect(restored.priority, task.priority);
    expect(restored.assigneeId, task.assigneeId);
    expect(restored.createdById, task.createdById);
  });
}
