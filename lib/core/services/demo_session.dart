import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI-only identity. These credentials are deliberately public demo credentials.
class DemoSession extends ChangeNotifier {
  DemoSession._();
  static final instance = DemoSession._();
  static const adminEmployeeId = 'emp_mahmud';
  static const staffEmployeeId = 'emp_shahina';
  static const _key = 'nec_demo_session_v1';
  String? _role;
  String _email = '';
  bool get signedIn => _role != null;
  bool get isAdmin => _role == 'admin';
  String get roleLabel => isAdmin ? 'Admin' : 'Staff';
  String get email => _email;
  String get employeeId => isAdmin ? adminEmployeeId : staffEmployeeId;
  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) {
        return;
      }
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (['admin', 'staff'].contains(json['role']) &&
          json['email'] is String) {
        _role = json['role'] as String;
        _email = json['email'] as String;
      }
    } catch (_) {
      _role = null;
      _email = '';
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const FormatException('Please enter your email and password.');
    }
    final normalized = email.trim().toLowerCase();
    final role = normalized == 'admin@neonecy.com' && password == '12345678'
        ? 'admin'
        : 'staff';
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
        _key, jsonEncode({'role': role, 'email': normalized}))) {
      throw const FormatException(
          'Unable to save this demo session. Please try again.');
    }
    _role = role;
    _email = normalized;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!await (await SharedPreferences.getInstance()).remove(_key)) {
      throw const FormatException('Unable to sign out. Please try again.');
    }
    _role = null;
    _email = '';
    notifyListeners();
  }
}
