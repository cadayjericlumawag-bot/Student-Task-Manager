import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../sql_helper/database_helper.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const channelId = 'high_importance_channel';
  static const channelName = 'High Importance Notifications';
  static const channelDescription =
      'This channel is used for important notifications.';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iOSInitSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    int? userId,
    String? payload,
  }) async {
    if (!await _shouldShowNotification()) return;

    // Save notification to database
    await DatabaseHelper.createNotification(
      title: title,
      message: body,
      type: type.index,
      timestamp: DateTime.now(),
      data: payload,
      userId: userId,
    );

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationType type,
    int? userId,
    String? payload,
  }) async {
    // Save notification to database with future timestamp
    await DatabaseHelper.createNotification(
      title: title,
      message: body,
      type: type.index,
      timestamp: scheduledDate,
      data: payload,
      userId: userId,
    );
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<bool> _shouldShowNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final quietHoursEnabled = prefs.getBool('quietHoursEnabled') ?? false;

    if (!quietHoursEnabled) return true;

    final now = TimeOfDay.now();
    final startHour = prefs.getInt('quietHoursStartHour') ?? 22;
    final startMinute = prefs.getInt('quietHoursStartMinute') ?? 0;
    final endHour = prefs.getInt('quietHoursEndHour') ?? 7;
    final endMinute = prefs.getInt('quietHoursEndMinute') ?? 0;

    final start = TimeOfDay(hour: startHour, minute: startMinute);
    final end = TimeOfDay(hour: endHour, minute: endMinute);

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Normal range (e.g., 22:00 - 07:00)
      return currentMinutes < startMinutes || currentMinutes >= endMinutes;
    } else {
      // Overnight range (e.g., 22:00 - 07:00)
      return currentMinutes < startMinutes && currentMinutes >= endMinutes;
    }
  }
}
