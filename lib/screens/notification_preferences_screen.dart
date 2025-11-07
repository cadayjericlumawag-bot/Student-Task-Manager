import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _quietHoursEnabled = false;

  final Map<String, bool> _notificationTypes = {
    'Due Date Reminders': true,
    'Overdue Alerts': true,
    'Task Updates': true,
    'Completion Notifications': true,
    'Daily Summaries': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // TODO: Load preferences from SharedPreferences
  }

  Future<void> _savePreferences() async {
    // TODO: Save preferences to SharedPreferences
  }

  Future<TimeOfDay?> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
  ) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              hourMinuteTextColor: Theme.of(context).primaryColor,
              dayPeriodTextColor: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          // Notification Types Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notification Types',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._notificationTypes.entries.map(
            (entry) => SwitchListTile(
              title: Text(entry.key, style: GoogleFonts.poppins()),
              value: entry.value,
              onChanged: (bool value) {
                setState(() {
                  _notificationTypes[entry.key] = value;
                });
                _savePreferences();
              },
            ),
          ),
          const Divider(),

          // Sound and Vibration Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sound & Vibration',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: Text('Sound', style: GoogleFonts.poppins()),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
              });
              _savePreferences();
            },
          ),
          SwitchListTile(
            title: Text('Vibration', style: GoogleFonts.poppins()),
            value: _vibrationEnabled,
            onChanged: (bool value) {
              setState(() {
                _vibrationEnabled = value;
              });
              _savePreferences();
            },
          ),
          const Divider(),

          // Quiet Hours Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Quiet Hours',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: Text('Enable Quiet Hours', style: GoogleFonts.poppins()),
            value: _quietHoursEnabled,
            onChanged: (bool value) {
              setState(() {
                _quietHoursEnabled = value;
              });
              _savePreferences();
            },
          ),
          if (_quietHoursEnabled) ...[
            ListTile(
              title: Text('Start Time', style: GoogleFonts.poppins()),
              trailing: Text(
                _quietHoursStart.format(context),
                style: GoogleFonts.poppins(),
              ),
              onTap: () async {
                final TimeOfDay? time = await _selectTime(
                  context,
                  _quietHoursStart,
                );
                if (time != null) {
                  setState(() {
                    _quietHoursStart = time;
                  });
                  _savePreferences();
                }
              },
            ),
            ListTile(
              title: Text('End Time', style: GoogleFonts.poppins()),
              trailing: Text(
                _quietHoursEnd.format(context),
                style: GoogleFonts.poppins(),
              ),
              onTap: () async {
                final TimeOfDay? time = await _selectTime(
                  context,
                  _quietHoursEnd,
                );
                if (time != null) {
                  setState(() {
                    _quietHoursEnd = time;
                  });
                  _savePreferences();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
