import 'dart:convert';
import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/employee.dart';

class EmployeeCache {
  const EmployeeCache(this._preferences);

  final PreferencesStore _preferences;

  String _key(String account, bool admin) =>
      'nec_api_employees_v1_${admin ? 'admin' : 'staff'}_$account';

  Future<List<Employee>?> read(String account, bool admin) async {
    await _preferences.remove('nec_employees_v1');
    final raw = await _preferences.read(_key(account, admin));
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((item) =>
              Employee.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      /* Discard invalid API records. */
    } on TypeError {
      /* The old local employee/login cache is never used. */
    }
    await _preferences.remove(_key(account, admin));
    return null;
  }

  Future<void> save(String account, bool admin, List<Employee> employees) =>
      _preferences.write(_key(account, admin),
          jsonEncode(employees.map((e) => e.toJson()).toList()));
}
