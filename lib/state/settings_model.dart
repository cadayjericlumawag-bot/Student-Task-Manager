import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsModel extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  String get selectedLanguage => _selectedLanguage;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled =
          prefs.getBool('notifications') ?? _notificationsEnabled;
      _darkMode = prefs.getBool('darkMode') ?? _darkMode;
      _selectedLanguage = prefs.getString('language') ?? _selectedLanguage;
    } on MissingPluginException catch (e) {
      // Platform plugin not available (e.g., during certain test runs or
      // if the app wasn't fully restarted after adding the plugin). Fall
      // back to default values and continue.
      if (kDebugMode) {
        // ignore: avoid_print
        print('SharedPreferences plugin not available: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error loading preferences: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications', value);
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('SharedPreferences plugin not available: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error saving notifications preference: $e');
      }
    }
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', value);
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('SharedPreferences plugin not available: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error saving darkMode preference: $e');
      }
    }
  }

  Future<void> setLanguage(String lang) async {
    _selectedLanguage = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('SharedPreferences plugin not available: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error saving language preference: $e');
      }
    }
  }
}
