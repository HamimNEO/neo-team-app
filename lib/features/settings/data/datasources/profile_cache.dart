import 'dart:convert';

import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/account_profile.dart';

class ProfileCache {
  const ProfileCache(this._store);

  final PreferencesStore _store;

  static String keyFor(String userId) => 'nec_account_profile_v1_$userId';

  Future<AccountProfile?> read(String userId) async {
    final key = keyFor(userId);
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final profile = AccountProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      if (profile.id == userId) return profile;
    } on FormatException {
      // Invalid cached identities are discarded.
    } on TypeError {
      // Invalid cached schemas are discarded.
    }
    await _store.remove(key);
    return null;
  }

  Future<void> save(AccountProfile profile) =>
      _store.write(keyFor(profile.id), jsonEncode(profile.toJson()));
}
