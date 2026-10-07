import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/employee.dart';
import 'employee_seed.dart';
import '../../../core/services/demo_session.dart';
import '../../auth/domain/models/employee_login.dart';

/// Local data for the UI phase. Replace with the authenticated API repository
/// when employee management and payroll are connected to the backend.
class EmployeeStore extends ChangeNotifier {
  EmployeeStore._() {
    DemoSession.instance.addListener(notifyListeners);
  }

  static final instance = EmployeeStore._();
  static const _key = 'nec_employees_v1';

  static String get currentEmployeeId => DemoSession.instance.employeeId;
  List<Employee> _employees = List.of(seedEmployees);
  Map<String, EmployeeLogin> _logins = {};
  Future<void>? _loading;
  Future<void> _pendingWrite = Future.value();
  String? loadError;

  List<Employee> get employees => List.unmodifiable(_employees);

  List<Employee> get staffEmployees => _employees
      .where((employee) =>
          employee.id != DemoSession.adminEmployeeId &&
          !employee.isAdministrator)
      .toList();

  bool isStaffEmployee(String id) {
    final employee = byId(id);
    return employee != null &&
        id != DemoSession.adminEmployeeId &&
        !employee.isAdministrator;
  }

  Employee get currentEmployee => byId(currentEmployeeId)!;

  String get nextEmployeeCode {
    var largest = 0;
    for (final employee in _employees) {
      final number =
          int.tryParse(employee.displayCode.replaceFirst('NEC-EMP-', ''));
      if (number != null && number > largest) largest = number;
    }
    return 'NEC-EMP-${(largest + 1).toString().padLeft(3, '0')}';
  }

  Employee? byId(String id) {
    for (final employee in _employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        final records =
            decoded is List ? decoded : (decoded as Map)['employees'] as List;
        final restored = records
            .map((item) =>
                Employee.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (![DemoSession.adminEmployeeId, DemoSession.staffEmployeeId]
            .every((id) => restored.any((item) => item.id == id))) {
          throw const FormatException('Current employee is missing');
        }
        _employees = restored;
        if (decoded is Map && decoded['logins'] is Map) {
          _logins = (decoded['logins'] as Map).map((id, value) => MapEntry(
              id as String,
              EmployeeLogin.fromJson(Map<String, dynamic>.from(value as Map))));
        }
      }
    } catch (_) {
      loadError =
          'Employee data could not be loaded. Restart the app to try again.';
    }
  }

  bool hasLogin(String employeeId) => _logins.containsKey(employeeId);

  String loginEmailFor(String employeeId) =>
      _logins[employeeId]?.email ?? byId(employeeId)?.email ?? '';

  Future<void> verifyAdminPassword(String password, {String? actorId}) async {
    final actor = actorId ?? DemoSession.instance.employeeId;
    await load();
    if (loadError != null) throw FormatException(loadError!);
    if (!DemoSession.instance.signedIn ||
        !DemoSession.instance.isAdmin ||
        actor != DemoSession.instance.employeeId) {
      throw const FormatException(
          'Sign in as administrator to manage passwords.');
    }
    final valid = _logins[actor]?.matches(password) ??
        DemoSession.instance.matchesSessionPassword(password);
    if (!valid) {
      throw const FormatException('Your admin password is incorrect.');
    }
  }

  Future<String?> revealEmployeePassword(
      String employeeId, String adminPassword) async {
    final actor = DemoSession.instance.employeeId;
    await verifyAdminPassword(adminPassword, actorId: actor);
    if (!isStaffEmployee(employeeId)) {
      throw const FormatException(
          'Select a staff account to manage its password.');
    }
    return _logins[employeeId]?.currentPassword;
  }

  Future<void> resetEmployeePassword(
      String employeeId, String newPassword, String adminPassword) {
    final actor = DemoSession.instance.employeeId;
    final write = _pendingWrite.then((_) async {
      await verifyAdminPassword(adminPassword, actorId: actor);
      if (!isStaffEmployee(employeeId)) {
        throw const FormatException(
            'Select a staff account to manage its password.');
      }
      final error = EmployeeLogin.passwordError(newPassword);
      if (error != null) throw FormatException(error);
      final email = DemoSession.normalizeLoginEmail(loginEmailFor(employeeId));
      if (email.isEmpty ||
          email == DemoSession.adminEmail ||
          _logins.entries.any((entry) =>
              entry.key != employeeId && entry.value.email == email)) {
        throw const FormatException('This employee needs a unique work email.');
      }
      final updated = {
        ..._logins,
        employeeId:
            EmployeeLogin.create(email, newPassword, revealCurrent: true)
      };
      final prefs = await SharedPreferences.getInstance();
      await verifyAdminPassword(adminPassword, actorId: actor);
      if (!await prefs.setString(_key, _encode(_employees, updated))) {
        throw const FormatException(
            'Unable to save the employee password. Please try again.');
      }
      _logins = updated;
      notifyListeners();
    });
    _pendingWrite =
        write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  Future<Employee?> authenticate(String email, String password) async {
    await load();
    if (loadError != null) throw FormatException(loadError!);
    email = DemoSession.normalizeLoginEmail(email);
    for (final entry in _logins.entries) {
      final employee = byId(entry.key);
      if (email == DemoSession.adminEmail &&
          entry.key != DemoSession.adminEmployeeId) {
        continue;
      }
      final reservedAdmin = email == DemoSession.adminEmail &&
          entry.key == DemoSession.adminEmployeeId;
      if (!reservedAdmin &&
          entry.value.email != email &&
          employee?.email.trim().toLowerCase() != email) {
        continue;
      }
      if (!entry.value.matches(password)) {
        throw const FormatException('Incorrect password for this account.');
      }
      if (employee == null || employee.status != 'Active') {
        throw const FormatException(
            'This account is inactive. Contact your administrator.');
      }
      return employee;
    }
    return null;
  }

  String _encode(List<Employee> employees, Map<String, EmployeeLogin> logins) =>
      jsonEncode({
        'version': 2,
        'employees': employees.map((item) => item.toJson()).toList(),
        'logins': logins.map((id, login) => MapEntry(id, login.toJson()))
      });

  Future<void> changePassword(String currentPassword, String newPassword) {
    final actor = DemoSession.instance.employeeId;
    final write = _pendingWrite.then((_) async {
      await load();
      if (loadError != null) throw FormatException(loadError!);
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor) {
        throw const FormatException('Sign in again to change your password.');
      }
      final login = _logins[actor];
      final matches = login?.matches(currentPassword) ??
          DemoSession.instance.matchesSessionPassword(currentPassword);
      if (!matches) {
        throw const FormatException('Your current password is incorrect.');
      }
      final error = EmployeeLogin.passwordError(newPassword);
      if (error != null) throw FormatException(error);
      if (newPassword == currentPassword) {
        throw const FormatException('Choose a different new password.');
      }
      final email = DemoSession.normalizeLoginEmail(
          login?.email ?? DemoSession.instance.email);
      if ((email == DemoSession.adminEmail &&
              actor != DemoSession.adminEmployeeId) ||
          _employees.any((employee) =>
              employee.id != actor &&
              employee.email.trim().toLowerCase() == email) ||
          _logins.entries.any(
              (entry) => entry.key != actor && entry.value.email == email)) {
        throw const FormatException(
            'Sign in with your own work email before changing your password.');
      }
      final updated = {
        ..._logins,
        actor: EmployeeLogin.create(email, newPassword,
            revealCurrent: !DemoSession.instance.isAdmin)
      };
      final prefs = await SharedPreferences.getInstance();
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor) {
        throw const FormatException('Sign in again to change your password.');
      }
      if (!await prefs.setString(_key, _encode(_employees, updated))) {
        throw const FormatException(
            'Unable to save your password. Please try again.');
      }
      _logins = updated;
      notifyListeners();
    });
    _pendingWrite =
        write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }

  Future<void> save(Employee employee, {String? initialPassword}) {
    final actor = DemoSession.instance.employeeId;
    final write = _pendingWrite.then((_) async {
      await load();
      if (loadError != null) throw StateError(loadError!);
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor ||
          (!DemoSession.instance.isAdmin && employee.id != currentEmployeeId)) {
        throw const FormatException(
            'Administrator access is required to manage other employees.');
      }
      for (final other in _employees) {
        if (other.id == employee.id) continue;
        if (other.email.trim().toLowerCase() ==
                employee.email.trim().toLowerCase() ||
            _logins[other.id]?.email == employee.email.trim().toLowerCase()) {
          throw const FormatException(
              'This work email is already used by another employee.');
        }
        if (other.displayCode.toLowerCase() ==
            employee.displayCode.toLowerCase()) {
          throw const FormatException('This employee ID is already in use.');
        }
      }
      if (DemoSession.normalizeLoginEmail(employee.email) ==
              DemoSession.adminEmail &&
          employee.id != DemoSession.adminEmployeeId) {
        throw const FormatException(
            'This email is reserved for the demo administrator.');
      }
      final updated = List<Employee>.of(_employees);
      final logins = Map<String, EmployeeLogin>.of(_logins);
      if (initialPassword != null) {
        if (!DemoSession.instance.isAdmin || logins.containsKey(employee.id)) {
          throw const FormatException(
              'The employee must change their own existing password.');
        }
        final error = EmployeeLogin.passwordError(initialPassword);
        if (error != null) throw FormatException(error);
        logins[employee.id] = EmployeeLogin.create(
            employee.email, initialPassword,
            revealInitial: true);
      } else if (logins[employee.id] != null &&
          byId(employee.id)?.email.trim().toLowerCase() !=
              employee.email.trim().toLowerCase()) {
        logins[employee.id] = logins[employee.id]!.withEmail(employee.email);
      }
      final index = updated.indexWhere((item) => item.id == employee.id);
      if (index == -1) {
        updated.add(employee);
      } else {
        updated[index] = employee;
      }
      final prefs = await SharedPreferences.getInstance();
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor) {
        throw const FormatException('Sign in again to save employee details.');
      }
      final success = await prefs.setString(_key, _encode(updated, logins));
      if (!success) {
        throw StateError(
            'Employee details could not be saved. Please try again.');
      }
      _employees = updated;
      _logins = logins;
      notifyListeners();
    });
    _pendingWrite =
        write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }
}
