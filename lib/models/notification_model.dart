enum NotificationType {
  reminder,
  update,
  completion,
  dueDate,
  overdue,
  dailySummary,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.update:
        return 'Update';
      case NotificationType.completion:
        return 'Completion';
      case NotificationType.dueDate:
        return 'Due Date';
      case NotificationType.overdue:
        return 'Overdue';
      case NotificationType.dailySummary:
        return 'Daily Summary';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.reminder:
        return '🔔';
      case NotificationType.update:
        return '📝';
      case NotificationType.completion:
        return '✅';
      case NotificationType.dueDate:
        return '📅';
      case NotificationType.overdue:
        return '⚠️';
      case NotificationType.dailySummary:
        return '📊';
    }
  }
}

class NotificationItem {
  final int? id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  NotificationItem copyWith({
    int? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'isRead': isRead ? 1 : 0,
      'data': data?.toString(),
    };
  }

  static NotificationItem fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: NotificationType.values[map['type'] as int],
      isRead: (map['isRead'] as int) == 1,
      data: map['data'] != null ? {} : null, // Parse data string if needed
    );
  }
}
