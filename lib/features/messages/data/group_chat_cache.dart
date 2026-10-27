import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/group_chat.dart';

class GroupChatCache {
  String get _key =>
      'nec_group_chats_api_v3_${AuthSession.instance.user?.id ?? 'signed_out'}_${Uri.encodeComponent(AppConfig.apiBaseUrl)}';

  Future<({List<GroupChat> groups, Set<String> seeded})> read() async {
    final key = _key;
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return (groups: <GroupChat>[], seeded: <String>{});
    final data = jsonDecode(raw) as Map;
    return (
      groups: (data['groups'] as List)
          .map((g) => GroupChat.fromJson(Map<String, dynamic>.from(g as Map)))
          .toList(),
      seeded: Set<String>.from(data['seededScopes'] as List)
    );
  }

  Future<void> save(List<GroupChat> groups, Set<String> seeded) async {
    final key = _key;
    final saved = await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode({
          'version': 1,
          'groups': groups.map((g) => g.toJson()).toList(),
          'seededScopes': seeded.toList()
        }));
    if (!saved) {
      throw const FormatException('Unable to save group chats. Try again.');
    }
  }
}
