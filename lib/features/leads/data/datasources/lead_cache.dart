import 'dart:convert';
import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/lead.dart';

class LeadCache {
  const LeadCache(this._preferences);

  final PreferencesStore _preferences;

  static String keyFor(String accountId, {bool admin = true}) =>
      'nec_leads_api_v1_${admin ? 'admin' : 'staff'}_$accountId';

  Future<List<Lead>?> read(String accountId, {bool admin = true}) async {
    await _preferences.remove('nec_leads_v1');
    final raw = await _preferences.read(keyFor(accountId, admin: admin));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as List;
      return value
          .map((item) => Lead.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on FormatException {
      // Discard corrupted cache
    } on TypeError {
      // Discard incompatible schema
    }
    await _preferences.remove(keyFor(accountId, admin: admin));
    return null;
  }

  Future<void> save(String accountId, List<Lead> items, {bool admin = true}) =>
      _preferences.write(keyFor(accountId, admin: admin),
          jsonEncode(items.map((l) => l.toJson()).toList()));
}
