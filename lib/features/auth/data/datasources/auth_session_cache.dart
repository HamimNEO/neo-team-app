import 'dart:convert';

import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/auth_session_data.dart';

class AuthSessionCache {
  const AuthSessionCache(this._store);

  static const key = 'nec_auth_session_v1';
  static const legacyKey = 'nec_demo_session_v1';
  final PreferencesStore _store;

  Future<AuthSessionData?> read() async {
    await _store.remove(legacyKey);
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final data = AuthSessionData.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      if (!data.isExpired) return data;
    } on FormatException {
      // Discard invalid caches instead of signing in with partial data.
    } on TypeError {
      // An older or damaged schema requires a fresh login.
    }
    await clear();
    return null;
  }

  Future<void> save(AuthSessionData session) =>
      _store.write(key, jsonEncode(session.toJson()));

  Future<void> clear() async {
    await _store.remove(key);
    await _store.remove(legacyKey);
  }
}
