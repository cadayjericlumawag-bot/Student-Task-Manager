import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _soundEnabledKey = 'notification_sound_enabled';
  static const String _vibrationEnabledKey = 'notification_vibration_enabled';
  static const String _quietHoursEnabledKey = 'quiet_hours_enabled';
  static const String _quietHoursStartHourKey = 'quiet_hours_start_hour';
  static const String _quietHoursStartMinuteKey = 'quiet_hours_start_minute';
  static const String _quietHoursEndHourKey = 'quiet_hours_end_hour';
  static const String _quietHoursEndMinuteKey = 'quiet_hours_end_minute';

  // Notification type keys
  static const String _dueDateRemindersKey = 'notification_due_date_reminders';
  static const String _overdueAlertsKey = 'notification_overdue_alerts';
  static const String _taskUpdatesKey = 'notification_task_updates';
  static const String _completionNotificationsKey = 'notification_completion';
  static const String _dailySummariesKey = 'notification_daily_summaries';

  Future<void> saveNotificationSound(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<bool> getNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> saveVibration(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  Future<bool> getVibration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> saveQuietHoursEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quietHoursEnabledKey, enabled);
  }

  Future<bool> getQuietHoursEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quietHoursEnabledKey) ?? false;
  }

  Future<void> saveQuietHoursStart(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietHoursStartHourKey, time.hour);
    await prefs.setInt(_quietHoursStartMinuteKey, time.minute);
  }

  Future<TimeOfDay> getQuietHoursStart() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_quietHoursStartHourKey) ?? 22;
    final minute = prefs.getInt(_quietHoursStartMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveQuietHoursEnd(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quietHoursEndHourKey, time.hour);
    await prefs.setInt(_quietHoursEndMinuteKey, time.minute);
  }

  Future<TimeOfDay> getQuietHoursEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_quietHoursEndHourKey) ?? 7;
    final minute = prefs.getInt(_quietHoursEndMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveNotificationType(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);
  }

  Future<bool> getNotificationType(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  Future<Map<String, bool>> getAllNotificationTypes() async {
    return {
      'Due Date Reminders': await getNotificationType(_dueDateRemindersKey),
      'Overdue Alerts': await getNotificationType(_overdueAlertsKey),
      'Task Updates': await getNotificationType(_taskUpdatesKey),
      'Completion Notifications': await getNotificationType(
        _completionNotificationsKey,
      ),
      'Daily Summaries': await getNotificationType(_dailySummariesKey),
    };
  }

  Future<void> saveAllNotificationTypes(Map<String, bool> types) async {
    await saveNotificationType(
      _dueDateRemindersKey,
      types['Due Date Reminders'] ?? true,
    );
    await saveNotificationType(
      _overdueAlertsKey,
      types['Overdue Alerts'] ?? true,
    );
    await saveNotificationType(_taskUpdatesKey, types['Task Updates'] ?? true);
    await saveNotificationType(
      _completionNotificationsKey,
      types['Completion Notifications'] ?? true,
    );
    await saveNotificationType(
      _dailySummariesKey,
      types['Daily Summaries'] ?? true,
    );
  }
}
