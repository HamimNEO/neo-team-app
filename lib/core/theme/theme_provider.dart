import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeStyle {
  defaultMode,
  bluish,
  eyeProtect,
}

class ThemeProvider extends ChangeNotifier {
  static const String _prefKeyMode = 'nec_theme_mode';
  static const String _prefKeyStyle = 'nec_theme_style';

  AppThemeMode _mode = AppThemeMode.light;
  AppThemeStyle _style = AppThemeStyle.defaultMode;

  ThemeProvider() {
    _loadFromPreferences();
  }

  AppThemeMode get mode => _mode;

  AppThemeStyle get style => _style;

  bool get isDark => _mode == AppThemeMode.dark;

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

  String get styleTitle {
    switch (_style) {
      case AppThemeStyle.defaultMode:
        return 'Default';
      case AppThemeStyle.bluish:
        return 'Bluish';
      case AppThemeStyle.eyeProtect:
        return 'Eyes Protect';
    }
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKeyMode);
      if (savedMode != null) {
        if (savedMode == 'dark') {
          _mode = AppThemeMode.dark;
        } else if (savedMode == 'light') {
          _mode = AppThemeMode.light;
        } else if (savedMode == 'system') {
          _mode = AppThemeMode.system;
        }
      } else {
        // Explicit default: Light mode
        _mode = AppThemeMode.light;
      }

      final savedStyle = prefs.getString(_prefKeyStyle);
      if (savedStyle != null) {
        if (savedStyle == 'bluish') {
          _style = AppThemeStyle.bluish;
        } else if (savedStyle == 'eye_protect' || savedStyle == 'yellow') {
          _style = AppThemeStyle.eyeProtect;
        } else {
          _style = AppThemeStyle.defaultMode;
        }
      }
      notifyListeners();
    } catch (_) {
      // Fallback to default light mode on storage error
      _mode = AppThemeMode.light;
      _style = AppThemeStyle.defaultMode;
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (mode) {
        case AppThemeMode.light:
          await prefs.setString(_prefKeyMode, 'light');
          break;
        case AppThemeMode.dark:
          await prefs.setString(_prefKeyMode, 'dark');
          break;
        case AppThemeMode.system:
          await prefs.setString(_prefKeyMode, 'system');
          break;
      }
    } catch (_) {}
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await setMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  Future<void> setStyle(AppThemeStyle style) async {
    _style = style;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (style) {
        case AppThemeStyle.defaultMode:
          await prefs.setString(_prefKeyStyle, 'default');
          break;
        case AppThemeStyle.bluish:
          await prefs.setString(_prefKeyStyle, 'bluish');
          break;
        case AppThemeStyle.eyeProtect:
          await prefs.setString(_prefKeyStyle, 'eye_protect');
          break;
      }
    } catch (_) {}
  }
}
