import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/employee.dart';
import 'employee_seed.dart';
import '../../../core/services/demo_session.dart';

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
  Future<void>? _loading;
  Future<void> _pendingWrite = Future.value();
  String? loadError;

  List<Employee> get employees => List.unmodifiable(_employees);

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
        final restored = (jsonDecode(saved) as List)
            .map((item) =>
                Employee.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (![DemoSession.adminEmployeeId, DemoSession.staffEmployeeId]
            .every((id) => restored.any((item) => item.id == id))) {
          throw const FormatException('Current employee is missing');
        }
        _employees = restored;
      }
    } catch (_) {
      // Keep the original saved data intact and never overwrite a failed load.
      loadError =
          'Employee data could not be loaded. Restart the app to try again.';
    }
  }

  Future<void> save(Employee employee) {
    final write = _pendingWrite.then((_) async {
      if (loadError != null) throw StateError(loadError!);
      if (!DemoSession.instance.signedIn ||
          (!DemoSession.instance.isAdmin && employee.id != currentEmployeeId)) {
        throw const FormatException(
            'Administrator access is required to manage other employees.');
      }
      for (final other in _employees) {
        if (other.id == employee.id) continue;
        if (other.email.toLowerCase() == employee.email.toLowerCase()) {
          throw const FormatException(
              'This work email is already used by another employee.');
        }
        if (other.displayCode.toLowerCase() ==
            employee.displayCode.toLowerCase()) {
          throw const FormatException('This employee ID is already in use.');
        }
      }
      final updated = List<Employee>.of(_employees);
      final index = updated.indexWhere((item) => item.id == employee.id);
      if (index == -1) {
        updated.add(employee);
      } else {
        updated[index] = employee;
      }
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(
          _key, jsonEncode(updated.map((item) => item.toJson()).toList()));
      if (!success) {
        throw StateError(
            'Employee details could not be saved. Please try again.');
      }
      _employees = updated;
      notifyListeners();
    });
    _pendingWrite =
        write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return write;
  }
}
