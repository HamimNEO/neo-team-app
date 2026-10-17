import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../home/domain/models/work_overview.dart';
import '../domain/models/work_item.dart';
import 'datasources/work_item_api.dart';
import 'datasources/work_item_cache.dart';
import 'repositories/work_item_repository.dart';

class WorkItemStore extends FrameSafeNotifier {
  WorkItemStore({
    required AuthSession session,
    required WorkItemRepository repository,
  })  : _session = session,
        _repository = repository {
    _token = session.accessToken;
    session.addListener(_sessionChanged);
  }

  static final instance = _create();

  static WorkItemStore _create() {
    final session = AuthSession.instance;
    return WorkItemStore(
      session: session,
      repository: WorkItemRepository(
        api: WorkItemApi(ApiClient(
          baseUrl: () => AppConfig.apiBaseUrl,
          accessToken: () => session.accessToken,
          onUnauthorized: session.invalidate,
        )),
        cache: const WorkItemCache(PreferencesStore()),
      ),
    );
  }

  final AuthSession _session;
  final WorkItemRepository _repository;
  final Map<String, Map<String, dynamic>> _details = {};
  List<WorkItem> _workItems = [];
  WorkOverview _overview = const WorkOverview();
  String? _token;
  int _revision = 0;
  int _accountVersion = 0;

  int get accountVersion => _accountVersion;
  Future<void>? _loadFuture;
  Future<void>? _cacheReadFuture;
  Future<void> _cacheWrites = Future.value();
  bool loading = false, saving = false, hasData = false;
  String? error, loadError, cacheError, overviewError;
  bool hasOverview = false;

  bool get canManage => _session.isAdmin;

  List<WorkItem> get items => List.unmodifiable(_workItems);

  WorkOverview get overview => _overview;

  List<WorkItem> get tasks =>
      _workItems.where((i) => i.type.toLowerCase() == 'task').toList();

  List<WorkItem> get followUps =>
      _workItems.where((i) => i.type.toLowerCase() == 'followup').toList();

  List<WorkItem> get visits =>
      _workItems.where((i) => i.type.toLowerCase() == 'visit').toList();

  List<WorkItem> get issues =>
      _workItems.where((i) => i.type.toLowerCase() == 'issue').toList();

  WorkItem? byId(String id) {
    for (final item in _workItems) {
      if (item.id == id) return item;
    }
    final numeric = RegExp(r'\d+').stringMatch(id);
    if (numeric != null) {
      for (final item in _workItems) {
        if (item.id == numeric) return item;
      }
    }
    return null;
  }

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _revision++;
    _accountVersion++;
    _workItems = [];
    _details.clear();
    _overview = const WorkOverview();
    _loadFuture = null;
    _cacheReadFuture = null;
    loading = saving = hasData = false;
    error = cacheError = loadError = overviewError = null;
    hasOverview = false;
    notifyListeners();
  }

  /// Restore overview and work records before any remote request is needed.
  Future<void> restoreCache() => _token == null || (hasData && hasOverview)
      ? Future.value()
      : _cacheReadFuture ??= _restoreCache();

  Future<void> _restoreCache() async {
    final token = _token, revision = _revision;
    final account = _session.user!.id, admin = canManage;
    await Future.wait([
      () async {
        try {
          final cached = await _repository.readCache(account, admin: admin);
          if (token != _token || revision != _revision || hasData) return;
          if (cached != null) {
            _workItems = cached;
            hasData = true;
            _syncFollowUpReminders(cached);
            notifyListeners();
          }
        } catch (_) {}
      }(),
      () async {
        try {
          final cached = await _repository.readOverviewCache(account);
          if (token != _token || revision != _revision || hasOverview) return;
          if (cached != null) {
            _overview = cached;
            hasOverview = true;
            notifyListeners();
          }
        } catch (_) {}
      }(),
    ]);
  }

  Future<void> load({bool force = false, bool preferCache = false}) async {
    if (_token == null || saving) return Future.value();
    final token = _token;
    if (!force && preferCache) {
      await restoreCache();
      if (token != _token || (hasData && hasOverview)) return;
    }
    if (force) _loadFuture = null;
    await (_loadFuture ??= _load());
  }

  Future<void> _load() async {
    final token = _token!;
    final account = _session.user?.id ?? 'account';
    final revision = _revision;
    bool current() => token == _token && revision == _revision;
    loading = true;
    error = loadError = null;
    notifyListeners();

    await restoreCache();

    if (!current()) return;
    await Future.wait([
      () async {
        try {
          final items = await _repository.list(token, admin: canManage);
          if (current()) {
            _workItems = items;
            hasData = true;
            _syncFollowUpReminders(items);
            notifyListeners();
          }
        } catch (exception) {
          if (current()) error = loadError = messageFor(exception);
        }
      }(),
      () async {
        try {
          final overview = await _repository.overview(token, admin: canManage);
          if (current()) {
            _overview = overview;
            hasOverview = true;
            overviewError = null;
            notifyListeners();
          }
        } catch (exception) {
          if (current()) overviewError = messageFor(exception);
        }
      }(),
    ]);
    if (current()) {
      await _persist(account, token, revision);
      loading = false;
      _loadFuture = null;
      notifyListeners();
    }
  }

  bool _open(WorkItem item) => ![
        'completed',
        'done',
        'cancelled',
        'resolved',
        'closed'
      ].contains(item.status.toLowerCase());

  void _syncFollowUpReminders(List<WorkItem> items) {
    if (kIsWeb) return;
    final currentEmpId = _session.employeeId;
    final userEmpId = _session.user?.employeeId != null
        ? 'api_emp_${_session.user!.employeeId}'
        : null;
    final rawUserEmpId = _session.user?.employeeId.toString();
    final currentUserName = _session.user?.name.trim().toLowerCase();
    final now = DateTime.now();

    for (final item in items) {
      if (item.type.toLowerCase() != 'followup' || item.isCompleted) continue;

      final isAssigned = item.assigneeEmployeeId == currentEmpId ||
          (userEmpId != null && item.assigneeEmployeeId == userEmpId) ||
          (rawUserEmpId != null && item.assigneeEmployeeId == rawUserEmpId) ||
          (currentUserName != null &&
              item.assigneeName?.trim().toLowerCase() == currentUserName) ||
          (_session.isAdmin &&
              (item.assigneeEmployeeId == null ||
                  item.assigneeEmployeeId == 'api_emp_0' ||
                  item.assigneeEmployeeId == '0'));

      if (!isAssigned) continue;
      if (item.scheduledAt == null) continue;
      if (item.scheduledAt!
          .isBefore(now.subtract(const Duration(minutes: 10)))) {
        continue;
      }

      final reminderMinutes =
          (item.metadata['reminder_minutes'] as num?)?.toInt() ?? 15;
      final followUpId =
          int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
              item.id.hashCode.abs();

      NotificationService.instance
          .scheduleFollowUpReminder(
            id: followUpId,
            leadName: item.leadName ?? item.title,
            purpose: item.metadata['purpose']?.toString() ?? item.title,
            scheduledAt: item.scheduledAt!,
            reminderMinutes: reminderMinutes,
            method: item.metadata['method']?.toString(),
            leadId: item.leadId,
          )
          .ignore();
    }
  }

  int get dueFollowUps => followUps
      .where((i) =>
          _open(i) &&
          i.scheduledAt != null &&
          !i.scheduledAt!.isAfter(DateTime.now()))
      .length;

  int get todayVisits => visits.where((i) {
        final d = i.scheduledAt?.toLocal(), now = DateTime.now();
        return _open(i) &&
            d != null &&
            d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      }).length;

  int get openTasks => tasks.where(_open).length;

  int get openIssues => issues.where(_open).length;

  Future<void> _refreshOverview(String token) async {
    try {
      final overview = await _repository.overview(token, admin: canManage);
      if (token != _token) return;
      _overview = overview;
      hasOverview = true;
      overviewError = null;
      notifyListeners();
    } catch (exception) {
      if (token == _token) overviewError = messageFor(exception);
    }
  }

  void _requireCreate(Map<String, dynamic> payload) {
    if (canManage) return;
    final owner = payload['assignee_employee_id'];
    if (owner != null &&
        owner.toString().replaceFirst('api_emp_', '') !=
            '${_session.user?.employeeId}') {
      throw const ApiException(
          'Only an administrator can assign work to an employee.');
    }
    final permission = switch (payload['type']) {
      'task' => StaffPermission.createTask,
      'followup' => StaffPermission.scheduleFollowUp,
      'visit' => StaffPermission.scheduleVisit,
      'issue' => StaffPermission.reportIssue,
      _ => null,
    };
    if (permission == null || !StaffAccessStore.instance.allows(permission)) {
      throw const ApiException(
          'Your administrator has not enabled this action.');
    }
  }

  void _requireUpdate(String id, Map<String, dynamic> payload) {
    if (canManage) return;
    final owner = payload['assignee_employee_id'];
    if (owner != null &&
        owner.toString().replaceFirst('api_emp_', '') !=
            '${_session.user?.employeeId}') {
      throw const ApiException(
          'Only an administrator can assign work to an employee.');
    }
    final item = byId(id);
    if (item == null) {
      throw const ApiException('Load this work item before updating it.');
    }
    if (item.type == 'issue' &&
        ['completed', 'resolved', 'closed']
            .contains(payload['status']?.toString().toLowerCase())) {
      throw const ApiException(
          'Only an administrator can resolve reported issues.');
    }
    if (item.type == 'task') {
      final isStatusOnly = payload.length == 1 && payload.containsKey('status');
      final isAssignee =
          item.assigneeEmployeeId == 'api_emp_${_session.user?.employeeId}' ||
              item.assigneeEmployeeId == '${_session.user?.employeeId}';
      if (!StaffAccessStore.instance.allows(StaffPermission.editTask) &&
          !(isStatusOnly && isAssignee)) {
        throw const ApiException(
            'Your administrator has not enabled task updates.');
      }
    }
  }

  Future<WorkItem> create(Map<String, dynamic> payload) async {
    _requireCreate(payload);
    final token = _token;
    if (token == null) {
      throw const ApiException('Please sign in again.');
    }
    saving = true;
    notifyListeners();
    try {
      final item = await _repository.create(token, payload, admin: canManage);
      if (token != _token) {
        throw const ApiException('Your account changed. Please sign in again.');
      }
      _workItems = [item, ..._workItems];
      _syncFollowUpReminders([item]);
      final account = _session.user?.id ?? 'account';
      await _refreshOverview(token);
      await _persist(account, token, _revision);
      notifyListeners();
      return item;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<WorkItem> update(String id, Map<String, dynamic> payload) async {
    _requireUpdate(id, payload);
    final token = _token;
    if (token == null) {
      throw const ApiException('Please sign in again.');
    }
    saving = true;
    notifyListeners();
    try {
      final updated =
          await _repository.update(token, id, payload, admin: canManage);
      if (token != _token) {
        throw const ApiException('Your account changed. Please sign in again.');
      }
      final index = _workItems.indexWhere((i) => i.id == id);
      if (index >= 0) {
        _workItems[index] = updated;
      }
      _syncFollowUpReminders([updated]);
      final account = _session.user?.id ?? 'account';
      await _refreshOverview(token);
      await _persist(account, token, _revision);
      notifyListeners();
      return updated;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> _persist(String account, String token, int revision) async {
    final itemsSnapshot = List.of(_workItems);
    final overviewSnapshot = _overview;
    final previous = _cacheWrites;
    _cacheWrites = () async {
      await previous;
      if (_token != token || _revision != revision) return;
      try {
        if (hasData) {
          await _repository.saveCache(account, itemsSnapshot, admin: canManage);
        }
        if (hasOverview) {
          await _repository.saveOverviewCache(account, overviewSnapshot);
        }
      } catch (e) {
        cacheError = 'Unable to save offline work items.';
      }
    }();
    await _cacheWrites;
  }

  Map<String, dynamic>? detailsFor(String id) => _details[id];

  Future<Map<String, dynamic>> fetchDetails(String id,
      {String? type, bool force = false}) async {
    if (!force && _details.containsKey(id)) return _details[id]!;
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    final response =
        await _repository.details(token, id, type ?? byId(id)?.type ?? 'task');
    if (token != _token) throw const ApiException('Your account changed.');
    final raw =
        response['work_item'] ?? response['follow_up'] ?? response['visit'];
    if (raw is! Map) {
      throw const ApiException('The server returned invalid work details.');
    }
    final item = WorkItem.fromJson(Map<String, dynamic>.from(raw));
    final index = _workItems.indexWhere((w) => w.id == item.id);
    if (index < 0) {
      _workItems.add(item);
    } else {
      _workItems[index] = item;
    }
    _details[id] = response;
    notifyListeners();
    return response;
  }

  Future<void> completeFollowUp(String id, String result) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.completeFollowUp(token, id, result);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> rescheduleFollowUp(String id, String date, String time) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.rescheduleFollowUp(token, id, date, time);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  void _requireVisitAction(String id) {
    if (canManage) return;
    final item = byId(id);
    final userEmpId = '${_session.user?.employeeId}';
    final userName = _session.user?.name.toLowerCase();
    final isAssignee = item != null &&
        (item.assigneeEmployeeId == 'api_emp_$userEmpId' ||
            item.assigneeEmployeeId == userEmpId ||
            item.assigneeName?.toLowerCase() == userName);
    if (!isAssignee) {
      throw const ApiException(
          'Only the assigned team member or an administrator can conduct this visit.');
    }
  }

  Future<void> startVisitJourney(String id) async {
    _requireVisitAction(id);
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.startVisitJourney(token, id);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> markVisitArrived(String id) async {
    _requireVisitAction(id);
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.markVisitArrived(token, id);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> completeVisitReport(
      String id, Map<String, dynamic> payload) async {
    _requireVisitAction(id);
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.completeVisitReport(token, id, payload);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> rescheduleVisit(String id, String date, String time) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.rescheduleVisit(token, id, date, time);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> cancelVisit(String id, String reason) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.cancelVisit(token, id, reason);
      await load(force: true);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<void> addComment(String id, String body) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.addComment(token, id, body);
      await fetchDetails(id, force: true);
    } catch (exception) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOptions() async {
    final token = _token;
    if (token == null) return null;
    try {
      return await _repository.getOptions(token);
    } catch (_) {
      return null;
    }
  }

  static String messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return error.message;
    return 'The request failed. Please try again.';
  }
}
