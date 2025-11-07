import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_manager.dart';
import '../widgets/duration_picker_dialog.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType? _selectedFilter;
  bool _isLoading = true;
  bool _focusModeEnabled = false;
  DateTime? _focusModeEndTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _loadFocusMode();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      await context.read<NotificationManager>().loadNotifications();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _loadFocusMode() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeStr = prefs.getString('focusModeEndTime');
    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      if (endTime.isAfter(DateTime.now())) {
        if (!mounted) return;
        setState(() {
          _focusModeEnabled = true;
          _focusModeEndTime = endTime;
        });
      } else {
        await prefs.remove('focusModeEndTime');
      }
    }
  }

  Future<void> _disableFocusMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('focusModeEndTime');
    if (!mounted) return;
    setState(() {
      _focusModeEnabled = false;
      _focusModeEndTime = null;
    });
  }

  Future<void> _enableFocusMode() async {
    // Show duration picker first, before any async operation
    final duration = await showDialog<Duration>(
      context: context,
      builder: (context) => const DurationPickerDialog(),
    );

    if (duration != null && mounted) {
      final endTime = DateTime.now().add(duration);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('focusModeEndTime', endTime.toIso8601String());
      if (!mounted) return;
      setState(() {
        _focusModeEnabled = true;
        _focusModeEndTime = endTime;
      });
    }
  }

  void _toggleFocusMode() {
    if (_focusModeEnabled) {
      _disableFocusMode();
    } else {
      _enableFocusMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await context.read<NotificationManager>().markAllAsRead();
                  break;
                case 'delete_all':
                  await context
                      .read<NotificationManager>()
                      .deleteAllNotifications();
                  break;
                case 'focus_mode':
                  _toggleFocusMode();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Text('Delete all'),
              ),
              PopupMenuItem(
                value: 'focus_mode',
                child: Text(
                  _focusModeEnabled
                      ? 'Disable focus mode'
                      : 'Enable focus mode',
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_focusModeEnabled) _buildFocusModeBar(),
          Expanded(
            child: Consumer<NotificationManager>(
              builder: (context, manager, child) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = _selectedFilter != null
                    ? manager.getFilteredNotifications(_selectedFilter)
                    : manager.notifications;

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notifications[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeBar() {
    final remainingTime = _focusModeEndTime?.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(context).primaryColor.withAlpha(26),
      child: Row(
        children: [
          const Icon(Icons.do_not_disturb_on, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Focus Mode Active${remainingTime != null ? ' (${remainingTime.inMinutes}m remaining)' : ''}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleFocusMode,
            child: Text('Turn Off', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (notification.id != null) {
          context.read<NotificationManager>().deleteNotification(
            notification.id!,
          );
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Theme.of(context).disabledColor
              : Theme.of(context).primaryColor,
          child: Text(
            notification.type.icon,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              _formatTimestamp(notification.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        onTap: () {
          if (notification.id != null && !notification.isRead) {
            context.read<NotificationManager>().markAsRead(notification.id!);
          }
          _showNotificationDetail(notification);
        },
      ),
    );
  }

  void _showNotificationDetail(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: notification.isRead
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColor,
                  child: Text(
                    notification.type.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        notification.type.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(notification.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
