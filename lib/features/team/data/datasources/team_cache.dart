import 'dart:convert';
import '../../../../core/storage/preferences_store.dart';
import '../../domain/models/team_group.dart';

class TeamCache {
  const TeamCache(this._preferences);

  final PreferencesStore _preferences;

  String _key(String account, bool admin) =>
      'nec_api_teams_v1_${admin ? 'admin' : 'staff'}_$account';

  Future<List<TeamGroup>?> read(String account, bool admin) async {
    final key = _key(account, admin),
        raw = await _preferences.read(_key(account, admin));
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((r) => TeamGroup.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (_) {
      await _preferences.remove(key);
      return null;
    }
  }

  Future<void> save(String account, bool admin, List<TeamGroup> teams) =>
      _preferences.write(_key(account, admin),
          jsonEncode(teams.map((t) => t.toJson()).toList()));

  Future<TeamDetail?> readDetail(
      String account, bool admin, String name) async {
    final key = '${_key(account, admin)}_detail_${Uri.encodeComponent(name)}';
    final raw = await _preferences.read(key);
    if (raw == null) return null;
    try {
      return TeamDetail.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      await _preferences.remove(key);
      return null;
    }
  }

  Future<void> saveDetail(String account, bool admin, TeamDetail detail) =>
      _preferences.write(
          '${_key(account, admin)}_detail_${Uri.encodeComponent(detail.team.name)}',
          jsonEncode(detail.toJson()));

  Future<void> removeDetail(String account, bool admin, String name) =>
      _preferences.remove(
          '${_key(account, admin)}_detail_${Uri.encodeComponent(name)}');
}
