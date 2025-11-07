import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useSystemTheme = true;
  bool _darkMode = false;
  int _defaultPriority = 1;
  String _defaultDueTime = '23:59';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useSystem = await SettingsService.getUseSystemTheme();
    final dark = await SettingsService.getDarkMode();
    final pri = await SettingsService.getDefaultPriority();
    final due = await SettingsService.getDefaultDueTime();
    setState(() {
      _useSystemTheme = useSystem;
      _darkMode = dark;
      _defaultPriority = pri;
      _defaultDueTime = due;
      _loading = false;
    });
  }

  Future<void> _saveUseSystemTheme(bool v) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await SettingsService.setUseSystemTheme(v);
    setState(() => _useSystemTheme = v);
    if (v) {
      themeProvider.setThemeMode(ThemeMode.system);
    } else {
      themeProvider.setThemeMode(_darkMode ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _saveDarkMode(bool v) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await SettingsService.setDarkMode(v);
    setState(() => _darkMode = v);
    if (!_useSystemTheme) {
      themeProvider.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _saveDefaultPriority(int v) async {
    await SettingsService.setDefaultPriority(v);
    setState(() => _defaultPriority = v);
  }

  Future<void> _pickDefaultDueTime() async {
    final parts = _defaultDueTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 23,
      minute: int.tryParse(parts[1]) ?? 59,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      final hhmm = '$hh:$mm';
      await SettingsService.setDefaultDueTime(hhmm);
      setState(() => _defaultDueTime = hhmm);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Use system theme'),
                    value: _useSystemTheme,
                    onChanged: (v) => _saveUseSystemTheme(v),
                  ),
                  if (!_useSystemTheme) ...[
                    SwitchListTile(
                      title: const Text('Dark mode'),
                      value: _darkMode,
                      onChanged: (v) => _saveDarkMode(v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Task Defaults',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Default Priority'),
                    subtitle: Text(_priorityLabel(_defaultPriority)),
                    trailing: DropdownButton<int>(
                      value: _defaultPriority,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Low')),
                        DropdownMenuItem(value: 1, child: Text('Medium')),
                        DropdownMenuItem(value: 2, child: Text('High')),
                      ],
                      onChanged: (v) {
                        if (v != null) _saveDefaultPriority(v);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Default Due Time'),
                    subtitle: Text(
                      '$_defaultDueTime (used when only date is picked)',
                    ),
                    trailing: ElevatedButton(
                      onPressed: _pickDefaultDueTime,
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account heading removed because logout is available in the app drawer.
                  // Sign out removed from Settings because Logout is available in the app drawer.
                ],
              ),
            ),
    );
  }

  String _priorityLabel(int p) {
    switch (p) {
      case 0:
        return 'Low';
      case 2:
        return 'High';
      default:
        return 'Medium';
    }
  }
}
