import '../../../home/domain/models/work_overview.dart';
import '../../domain/models/work_item.dart';
import '../datasources/work_item_api.dart';
import '../datasources/work_item_cache.dart';

class WorkItemRepository {
  const WorkItemRepository({
    required WorkItemApi api,
    required WorkItemCache cache,
  })  : _api = api,
        _cache = cache;

  final WorkItemApi _api;
  final WorkItemCache _cache;

  Future<List<WorkItem>> list(String token,
          {required bool admin, String? type}) =>
      _api.list(token, admin: admin, type: type);

  Future<List<WorkItem>?> readCache(String accountId, {required bool admin}) =>
      _cache.readWorkItems(accountId, admin: admin);

  Future<void> saveCache(String accountId, List<WorkItem> items,
          {required bool admin}) =>
      _cache.saveWorkItems(accountId, items, admin: admin);

  Future<WorkItem> create(String token, Map<String, dynamic> payload,
          {bool admin = true}) =>
      _api.create(token, payload, admin: admin);

  Future<WorkItem> update(String token, String id, Map<String, dynamic> payload,
          {bool admin = true}) =>
      _api.update(token, id, payload, admin: admin);

  Future<WorkOverview> overview(String token, {bool admin = true}) =>
      _api.overview(token, admin: admin);

  Future<WorkOverview?> readOverviewCache(String accountId) =>
      _cache.readOverview(accountId);

  Future<void> saveOverviewCache(String accountId, WorkOverview overview) =>
      _cache.saveOverview(accountId, overview);

  Future<Map<String, dynamic>> completeFollowUp(
          String token, String id, String result) =>
      _api.completeFollowUp(token, id, result: result);

  Future<Map<String, dynamic>> rescheduleFollowUp(
          String token, String id, String date, String time) =>
      _api.rescheduleFollowUp(token, id, date: date, time: time);

  Future<Map<String, dynamic>> startVisitJourney(String token, String id) =>
      _api.startVisitJourney(token, id);

  Future<Map<String, dynamic>> markVisitArrived(String token, String id) =>
      _api.markVisitArrived(token, id);

  Future<Map<String, dynamic>> completeVisitReport(
          String token, String id, Map<String, dynamic> payload) =>
      _api.completeVisitReport(token, id, payload);

  Future<Map<String, dynamic>> rescheduleVisit(
          String token, String id, String date, String time) =>
      _api.rescheduleVisit(token, id, date: date, time: time);

  Future<Map<String, dynamic>> cancelVisit(
          String token, String id, String reason) =>
      _api.cancelVisit(token, id, reason: reason);

  Future<Map<String, dynamic>> addComment(
          String token, String id, String body) =>
      _api.addComment(token, id, body: body);

  Future<Map<String, dynamic>> getOptions(String token) =>
      _api.getWorkItemOptions(token);

  Future<Map<String, dynamic>> details(String token, String id, String type) =>
      _api.details(token, id, type);
}
