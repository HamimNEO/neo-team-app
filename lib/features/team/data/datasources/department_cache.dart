import 'dart:convert';
import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/department.dart';

class DepartmentCache {
  const DepartmentCache(this._preferences);

  final PreferencesStore _preferences;

  static String keyFor(String accountId, {bool admin = true}) =>
      'nec_departments_v1_${admin ? 'admin' : 'staff'}_$accountId';

  Future<List<DepartmentItem>?> read(String accountId,
      {bool admin = true}) async {
    final raw = await _preferences.read(keyFor(accountId, admin: admin));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as List;
      return value
          .map((item) =>
              DepartmentItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      // Discard invalid cached API records; never substitute demo data.
    } on TypeError {
      // A cache from another schema is not a department response.
    }
    await _preferences.remove(keyFor(accountId, admin: admin));
    return null;
  }

  Future<void> save(String accountId, List<DepartmentItem> items,
          {bool admin = true}) =>
      _preferences.write(keyFor(accountId, admin: admin),
          jsonEncode(items.map((d) => d.toJson()).toList()));
}
