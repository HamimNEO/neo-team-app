import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'nec_theme_mode';
  AppThemeMode _mode = AppThemeMode.light;

  ThemeProvider() {
    _loadFromPreferences();
  }

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        if (savedMode == 'dark') {
          _mode = AppThemeMode.dark;
        } else if (savedMode == 'light') {
          _mode = AppThemeMode.light;
        } else if (savedMode == 'system') {
          _mode = AppThemeMode.system;
        }
        notifyListeners();
      }
    } catch (_) {
      // Fallback to default light mode on storage error
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (mode) {
        case AppThemeMode.light:
          await prefs.setString(_prefKey, 'light');
          break;
        case AppThemeMode.dark:
          await prefs.setString(_prefKey, 'dark');
          break;
        case AppThemeMode.system:
          await prefs.setString(_prefKey, 'system');
          break;
      }
    } catch (_) {}
  }
}
