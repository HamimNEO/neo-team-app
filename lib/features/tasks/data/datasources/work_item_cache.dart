import 'dart:convert';
import '../../../../core/storage/preferences_store.dart';
import '../../../home/domain/models/work_overview.dart';
import '../../domain/models/work_item.dart';

class WorkItemCache {
  const WorkItemCache(this._preferences);

  final PreferencesStore _preferences;

  static String workItemsKey(String accountId, {bool admin = true}) =>
      'nec_work_items_api_v1_${admin ? 'admin' : 'staff'}_$accountId';

  static String overviewKey(String accountId) =>
      'nec_work_overview_api_v1_$accountId';

  Future<List<WorkItem>?> readWorkItems(String accountId,
      {bool admin = true}) async {
    final raw = await _preferences.read(workItemsKey(accountId, admin: admin));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as List;
      return value
          .map((item) =>
              WorkItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {}
    await _preferences.remove(workItemsKey(accountId, admin: admin));
    return null;
  }

  Future<void> saveWorkItems(String accountId, List<WorkItem> items,
          {bool admin = true}) =>
      _preferences.write(
        workItemsKey(accountId, admin: admin),
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  Future<WorkOverview?> readOverview(String accountId) async {
    final raw = await _preferences.read(overviewKey(accountId));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is Map) {
        return WorkOverview.fromJson(Map<String, dynamic>.from(value));
      }
    } catch (_) {}
    await _preferences.remove(overviewKey(accountId));
    return null;
  }

  Future<void> saveOverview(String accountId, WorkOverview overview) =>
      _preferences.write(
        overviewKey(accountId),
        jsonEncode(overview.toJson()),
      );
}
