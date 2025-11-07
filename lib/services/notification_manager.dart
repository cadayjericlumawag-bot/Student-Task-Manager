import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../sql_helper/database_helper.dart';
import 'notification_service.dart';

class NotificationManager extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  NotificationManager() {
    // Defer initialization until after the first frame so notifyListeners()
    // isn't called while widgets are being built (avoids setState during build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    await _notificationService.init();
    await loadNotifications();
  }

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = await DatabaseHelper.getCurrentUser();
      final userId = currentUser?['id'] as int?;

      final notificationsData = await DatabaseHelper.getNotifications(
        userId: userId,
        unreadOnly: unreadOnly,
      );

      _notifications = notificationsData.map((data) {
        return NotificationItem(
          id: data['id'] as int?,
          title: data['title'] as String,
          message: data['message'] as String,
          type: NotificationType.values[data['type'] as int],
          timestamp: DateTime.parse(data['timestamp'] as String),
          isRead: data['isRead'] == 1,
          data: data['data'] != null ? {} : null, // Parse the data if needed
        );
      }).toList();

      _unreadCount = await DatabaseHelper.getUnreadNotificationCount(
        userId: userId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error loading notifications: $e');
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await DatabaseHelper.markNotificationAsRead(id);
      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final currentUser = await DatabaseHelper.getCurrentUser();
      await DatabaseHelper.markAllNotificationsAsRead(
        userId: currentUser?['id'] as int?,
      );
      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await DatabaseHelper.deleteNotification(id);
      await loadNotifications();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final currentUser = await DatabaseHelper.getCurrentUser();
      await DatabaseHelper.deleteAllNotifications(
        userId: currentUser?['id'] as int?,
      );
      await loadNotifications();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    try {
      final currentUser = await DatabaseHelper.getCurrentUser();
      final userId = currentUser?['id'] as int?;

      final now = DateTime.now().millisecondsSinceEpoch;
      await _notificationService.showNotification(
        id: now.hashCode,
        title: title,
        body: body,
        type: type,
        userId: userId,
        payload: payload,
      );

      await loadNotifications();
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationType type,
    String? payload,
  }) async {
    try {
      final currentUser = await DatabaseHelper.getCurrentUser();
      final userId = currentUser?['id'] as int?;

      await _notificationService.scheduleNotification(
        id: scheduledDate.millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        type: type,
        userId: userId,
        payload: payload,
      );

      await loadNotifications();
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  List<NotificationItem> getFilteredNotifications(NotificationType? type) {
    if (type == null) {
      return notifications;
    }
    return notifications.where((n) => n.type == type).toList();
  }

  List<NotificationItem> getNotificationsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    return notifications.where((n) {
      return n.timestamp.isAfter(start) &&
          n.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> scheduleTaskNotifications(
    String taskTitle,
    DateTime dueDate,
  ) async {
    // Schedule due date reminder (1 day before)
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        title: 'Task Due Tomorrow',
        body: 'The task "$taskTitle" is due tomorrow',
        scheduledDate: oneDayBefore,
        type: NotificationType.dueDate,
        payload: 'task_due_tomorrow',
      );
    }

    // Schedule overdue notification (at due time if not completed)
    await scheduleNotification(
      title: 'Task Overdue',
      body: 'The task "$taskTitle" is now overdue',
      scheduledDate: dueDate,
      type: NotificationType.overdue,
      payload: 'task_overdue',
    );
  }
}
