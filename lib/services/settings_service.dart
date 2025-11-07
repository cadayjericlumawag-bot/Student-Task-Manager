import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyUseSystemTheme = 'appearance.useSystemTheme';
  static const _keyDarkMode = 'appearance.darkMode';
  static const _keyDefaultPriority = 'task.defaultPriority';
  static const _keyDefaultDueTime = 'task.defaultDueTime'; // stored as HH:mm

  // Appearance
  static Future<bool> getUseSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseSystemTheme) ?? true;
  }

  static Future<void> setUseSystemTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSystemTheme, value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // Task defaults
  /// priority: 0=low,1=medium,2=high
  static Future<int> getDefaultPriority() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultPriority) ?? 1;
  }

  static Future<void> setDefaultPriority(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultPriority, value);
  }

  // stored as "HH:mm" string
  static Future<String> getDefaultDueTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultDueTime) ?? '23:59';
  }

  static Future<void> setDefaultDueTime(String hhmm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultDueTime, hhmm);
  }
}
