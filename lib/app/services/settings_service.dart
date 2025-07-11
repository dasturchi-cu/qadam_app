import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('uz');

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  SettingsService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _darkMode = _prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _darkMode = enabled;
    await _prefs.setBool('darkMode', enabled);
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
} 