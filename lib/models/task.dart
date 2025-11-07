enum TaskStatus { todo, inProgress, completed, overdue }

enum TaskPriority { low, medium, high }

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final int assigneeId;
  final int createdById;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ownerUid;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    required this.assigneeId,
    required this.createdById,
    DateTime? createdAt,
    this.updatedAt,
    this.ownerUid,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.index,
      'priority': priority.index,
      'assigneeId': assigneeId,
      'createdById': createdById,
      'ownerUid': ownerUid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: TaskStatus.values[map['status'] as int],
      priority: TaskPriority.values[map['priority'] as int],
      assigneeId: map['assigneeId'] as int,
      createdById: map['createdById'] as int,
      ownerUid: map['ownerUid'] != null ? map['ownerUid'] as String : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  Task copyWith({
    int? newId,
    String? newTitle,
    String? newDescription,
    DateTime? newDueDate,
    TaskStatus? newStatus,
    TaskPriority? newPriority,
    int? newAssigneeId,
    int? newCreatedById,
    DateTime? newCreatedAt,
    DateTime? newUpdatedAt,
  }) {
    return Task(
      id: newId ?? id,
      title: newTitle ?? title,
      description: newDescription ?? description,
      dueDate: newDueDate ?? dueDate,
      status: newStatus ?? status,
      priority: newPriority ?? priority,
      assigneeId: newAssigneeId ?? assigneeId,
      createdById: newCreatedById ?? createdById,
      createdAt: newCreatedAt ?? createdAt,
      updatedAt: newUpdatedAt ?? updatedAt,
      ownerUid: ownerUid,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority, dueDate: $dueDate)';
  }
}
