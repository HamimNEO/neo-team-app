import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/models/employee_login.dart';
import '../../features/team/data/employee_store.dart';

/// UI-only identity. These credentials are deliberately public demo credentials.
class DemoSession extends ChangeNotifier {
  DemoSession._();

  static final instance = DemoSession._();
  static const adminEmployeeId = 'emp_mahmud';
  static const staffEmployeeId = 'emp_shahina';
  static const adminEmail = 'admin@neonecy.com';
  static const adminPassword = '12345678';

  static String normalizeLoginEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == 'admin.neonecy.com' ? adminEmail : normalized;
  }

  static const _key = 'nec_demo_session_v1';
  String? _role;
  String _email = '';
  String? _employeeId;
  EmployeeLogin? _sessionLogin;

  bool get signedIn => _role != null;

  bool get isAdmin => _role == 'admin';

  String get roleLabel => isAdmin ? 'Admin' : 'Staff';

  String get email => _email;

  String get employeeId =>
      _employeeId ?? (isAdmin ? adminEmployeeId : staffEmployeeId);

  bool matchesSessionPassword(String password) {
    if (_sessionLogin == null) {
      throw const FormatException(
          'Sign out and sign in again before changing your password.');
    }
    return _sessionLogin!.matches(password);
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) {
        return;
      }
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (['admin', 'staff'].contains(json['role']) &&
          json['email'] is String) {
        _role = json['role'] as String;
        _email = normalizeLoginEmail(json['email'] as String);
        _employeeId = json['employeeId'] as String?;
        if (json['passwordVerifier'] is Map) {
          _sessionLogin = EmployeeLogin.fromJson(
              Map<String, dynamic>.from(json['passwordVerifier'] as Map));
        }
        await EmployeeStore.instance.load();
        if (_email == adminEmail &&
            (_role != 'admin' || employeeId != adminEmployeeId)) {
          if (!(_sessionLogin?.matches(adminPassword) ?? false)) {
            throw const FormatException(
                'Sign in again with the admin credentials.');
          }
          await EmployeeStore.instance.authenticate(adminEmail, adminPassword);
          _role = 'admin';
          _employeeId = adminEmployeeId;
          _sessionLogin = _sessionLogin!.withEmail(adminEmail);
        }
        if (EmployeeStore.instance.byId(employeeId) == null) {
          throw const FormatException('This employee no longer exists.');
        }
        if (_email != json['email'] ||
            _role != json['role'] ||
            _employeeId != json['employeeId']) {
          if (!await prefs.setString(
              _key,
              jsonEncode({
                'role': _role,
                'email': _email,
                'employeeId': employeeId,
                if (_sessionLogin != null)
                  'passwordVerifier': _sessionLogin!.toJson(),
              }))) {
            throw const FormatException('Unable to restore this session.');
          }
        }
      }
    } catch (_) {
      _role = null;
      _email = '';
      _employeeId = null;
      _sessionLogin = null;
    }
  }

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const FormatException('Please enter your email and password.');
    }
    final normalized = normalizeLoginEmail(email);
    final employee =
        await EmployeeStore.instance.authenticate(normalized, password);
    final adminLogin = normalized == adminEmail;
    if (adminLogin && employee == null && password != adminPassword) {
      throw const FormatException(
          'Incorrect admin password. Please try again.');
    }
    final role = adminLogin
        ? 'admin'
        : employee != null
            ? (['Admin', 'Administrator'].contains(employee.systemRole)
                ? 'admin'
                : 'staff')
            : 'staff';
    final id = adminLogin
        ? adminEmployeeId
        : employee?.id ?? (role == 'admin' ? adminEmployeeId : staffEmployeeId);
    final verifier = EmployeeLogin.create(normalized, password);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
        _key,
        jsonEncode({
          'role': role,
          'email': normalized,
          'employeeId': id,
          'passwordVerifier': verifier.toJson()
        }))) {
      throw const FormatException(
          'Unable to save this demo session. Please try again.');
    }
    _role = role;
    _email = normalized;
    _employeeId = id;
    _sessionLogin = verifier;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!await (await SharedPreferences.getInstance()).remove(_key)) {
      throw const FormatException('Unable to sign out. Please try again.');
    }
    _role = null;
    _email = '';
    _employeeId = null;
    _sessionLogin = null;
    notifyListeners();
  }
}
