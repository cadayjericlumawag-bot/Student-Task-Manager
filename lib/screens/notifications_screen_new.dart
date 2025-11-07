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

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;
  bool _isLoading = true;
  bool _focusModeEnabled = false;
  DateTime? _focusModeEndTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      _loadFocusMode();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final contextCopy = context;
    final duration = await showDialog<Duration>(
      context: contextCopy,
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

  Future<void> _clearNotifications() async {
    await context.read<NotificationManager>().deleteAllNotifications();
  }

  void _openPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openPreferences,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all notifications'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Notifications'),
            Tab(text: 'Focus Mode'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNotificationsTab(), _buildFocusModeTab()],
      ),
    );
  }

  Widget _buildFocusModeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_focusModeEnabled) _buildFocusModeBar(),
          const SizedBox(height: 16),
          Text(
            'Focus Mode',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When Focus Mode is enabled, notifications will be silenced for the duration you choose.',
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 24),
          if (!_focusModeEnabled)
            ElevatedButton.icon(
              onPressed: _toggleFocusMode,
              icon: const Icon(Icons.do_not_disturb_on),
              label: Text('Enable Focus Mode', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Consumer<NotificationManager>(
      builder: (context, manager, child) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = _selectedFilter != null
            ? manager.notifications
                  .where((n) => n.type == _selectedFilter)
                  .toList()
            : manager.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Text(
              'No notifications',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            _buildFilterChips(manager),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationTile(notification);
                },
              ),
            ),
          ],
        );
      },
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

  Widget _buildFilterChips(NotificationManager manager) {
    final types = NotificationType.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text('All', style: GoogleFonts.poppins()),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              setState(() => _selectedFilter = null);
            },
          ),
          const SizedBox(width: 8),
          ...types.map((type) {
            final count = manager.notifications
                .where((n) => n.type == type)
                .length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  '${type.name} ($count)',
                  style: GoogleFonts.poppins(),
                ),
                selected: _selectedFilter == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? type : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        if (notification.id != null) {
          await context.read<NotificationManager>().deleteNotification(
            notification.id!,
          );
        }
      },
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(notification.title, style: GoogleFonts.poppins()),
        subtitle: Text(notification.message, style: GoogleFonts.poppins()),
        trailing: Text(
          _formatTimestamp(notification.timestamp),
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.reminder:
        iconData = Icons.alarm;
        color = Colors.blue;
        break;
      case NotificationType.update:
        iconData = Icons.update;
        color = Colors.green;
        break;
      case NotificationType.completion:
        iconData = Icons.task_alt;
        color = Colors.purple;
        break;
      case NotificationType.dueDate:
        iconData = Icons.event;
        color = Colors.orange;
        break;
      case NotificationType.overdue:
        iconData = Icons.warning;
        color = Colors.red;
        break;
      case NotificationType.dailySummary:
        iconData = Icons.assessment;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
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
