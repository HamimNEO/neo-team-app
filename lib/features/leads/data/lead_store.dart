import 'dart:typed_data';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_store.dart';
import '../domain/models/lead.dart';
import '../domain/models/lead_status.dart';
import 'datasources/lead_api.dart';
import 'datasources/lead_cache.dart';
import 'repositories/lead_repository.dart';

class LeadStore extends FrameSafeNotifier {
  LeadStore({
    required AuthSession session,
    required LeadRepository repository,
  })  : _session = session,
        _repository = repository {
    _token = session.accessToken;
    session.addListener(_sessionChanged);
  }

  static final instance = _create();

  static LeadStore _create() {
    final session = AuthSession.instance;
    return LeadStore(
      session: session,
      repository: LeadRepository(
        api: LeadApi(ApiClient(
          baseUrl: () => AppConfig.apiBaseUrl,
          accessToken: () => session.accessToken,
          onUnauthorized: session.invalidate,
        )),
        cache: const LeadCache(PreferencesStore()),
      ),
    );
  }

  final AuthSession _session;
  final LeadRepository _repository;
  List<Lead> _leads = [];
  String? _token;
  int _revision = 0;
  int _accountVersion = 0;

  int get accountVersion => _accountVersion;
  Future<void>? _loadFuture;
  Future<void>? _cacheReadFuture;
  Future<void> _cacheWrites = Future.value();
  bool loading = false, saving = false, hasData = false;
  String? loadError, error, cacheError, listWarning;

  bool get canManage => _session.isAdmin;

  List<Lead> get leads => List.unmodifiable(_leads);

  Lead? byId(String id) {
    for (final lead in _leads) {
      if (lead.id == id) return lead;
    }
    final numeric = RegExp(r'\d+').stringMatch(id);
    if (numeric != null) {
      for (final lead in _leads) {
        if (lead.id == numeric) return lead;
      }
    }
    return null;
  }

  String assigneeName(Lead lead) {
    if (lead.assignedEmployeeId != null &&
        lead.assignedEmployeeId!.isNotEmpty) {
      final employee = EmployeeStore.instance.byId(lead.assignedEmployeeId!);
      if (employee != null) return employee.name;
    }
    if (lead.assignedTo != null && lead.assignedTo!.isNotEmpty) {
      return lead.assignedTo!;
    }
    return 'Unassigned';
  }

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _revision++;
    _accountVersion++;
    _leads = [];
    _details.clear();
    _loadFuture = null;
    _cacheReadFuture = null;
    loading = saving = hasData = false;
    error = cacheError = loadError = listWarning = null;
    notifyListeners();
  }

  /// Restore this account's last successful response without using the network.
  Future<void> restoreCache() => _token == null || hasData
      ? Future.value()
      : _cacheReadFuture ??= _restoreCache();

  Future<void> _restoreCache() async {
    final token = _token, revision = _revision;
    final account = _session.user!.id, admin = canManage;
    try {
      final cached = await _repository.readCache(account, admin: admin);
      if (token != _token || revision != _revision || hasData) return;
      if (cached != null) {
        _leads = cached;
        hasData = true;
        notifyListeners();
      }
    } catch (_) {
      // A missing or unreadable cache must not prevent a live fetch.
    }
  }

  Future<void> load({bool force = false, bool preferCache = false}) async {
    if (_token == null || saving) return Future.value();
    final token = _token;
    if (!force && preferCache) {
      await restoreCache();
      if (token != _token || hasData) return;
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
    error = loadError = listWarning = null;
    notifyListeners();

    await restoreCache();

    if (!current()) return;
    try {
      final items =
          await _repository.list(token, admin: canManage, onFallback: () {
        if (current()) {
          listWarning =
              'The leads list API is unavailable. Showing permitted active leads from work assignments.';
        }
      });
      if (!current()) return;
      _leads = items;
      hasData = true;
      await _persist(account, token, revision);
    } catch (exception) {
      if (current()) {
        error = loadError = messageFor(exception);
      }
    } finally {
      if (current()) {
        loading = false;
        _loadFuture = null;
        notifyListeners();
      }
    }
  }

  void _validateAssignee(String? employeeId) {
    if (employeeId == null || employeeId.isEmpty) return;
    final employee = EmployeeStore.instance.byId(employeeId);
    if (employee == null || employee.status != 'Active') {
      throw const FormatException('Choose an active employee for this lead.');
    }
  }

  Future<Lead> save(Lead draft) async {
    final token = _token;
    if (token == null) {
      throw const ApiException('Please sign in again.');
    }

    final isNew = byId(draft.id) == null;
    final permission =
        isNew ? StaffPermission.createLead : StaffPermission.editLead;
    if (!canManage && !StaffAccessStore.instance.allows(permission)) {
      throw const FormatException(
          'Your administrator has not enabled this action.');
    }

    if (!canManage) {
      final existingOwner = byId(draft.id)?.assignedEmployeeId;
      final expected =
          isNew ? 'api_emp_${_session.user?.employeeId}' : existingOwner;
      if (draft.assignedEmployeeId != expected) {
        throw const ApiException(
            'Only an administrator can assign leads to an employee.');
      }
    }
    if (canManage) _validateAssignee(draft.assignedEmployeeId);

    saving = true;
    notifyListeners();
    try {
      final Lead saved;
      if (isNew) {
        saved = await _repository.create(token, draft, admin: canManage);
        if (token != _token) {
          throw const ApiException(
              'Your account changed. Please sign in again.');
        }
        _leads = [saved, ..._leads];
      } else {
        saved = await _repository.update(token, draft.id, draft.toApiPayload(),
            admin: canManage);
        if (token != _token) {
          throw const ApiException(
              'Your account changed. Please sign in again.');
        }
        final index = _leads.indexWhere((l) => l.id == draft.id);
        if (index >= 0) {
          _leads[index] = saved;
        } else {
          _leads = [saved, ..._leads];
        }
      }
      final account = _session.user?.id ?? 'account';
      await _persist(account, token, _revision);
      notifyListeners();
      return saved;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> reassign(String leadId, String? employeeId) async {
    final token = _token;
    if (token == null) {
      throw const ApiException('Please sign in again.');
    }
    if (!canManage) {
      throw const FormatException(
          'Administrator access is required to change lead assignments.');
    }

    _validateAssignee(employeeId);
    saving = true;
    notifyListeners();
    try {
      final updated = await _repository.reassign(token, leadId, employeeId);
      if (token != _token) {
        throw const ApiException('Your account changed. Please sign in again.');
      }
      final index = _leads.indexWhere((l) => l.id == leadId);
      if (index >= 0) {
        _leads[index] = updated;
      }
      final account = _session.user?.id ?? 'account';
      await _persist(account, token, _revision);
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> _persist(String account, String token, int revision) async {
    final snapshot = List.of(_leads);
    final previous = _cacheWrites;
    _cacheWrites = () async {
      await previous;
      if (_token != token || _revision != revision) return;
      try {
        await _repository.saveCache(account, snapshot, admin: canManage);
      } catch (e) {
        cacheError = 'Unable to save offline leads.';
      }
    }();
    await _cacheWrites;
  }

  final Map<String, Map<String, dynamic>> _details = {};

  Map<String, dynamic>? getDetails(String leadId) => _details[leadId];

  Future<Map<String, dynamic>?> fetchDetails(String leadId,
      {bool force = false}) async {
    final token = _token;
    if (token == null) return null;
    if (!force && _details.containsKey(leadId)) {
      return _details[leadId];
    }
    try {
      final response = await _repository.getDetails(token, leadId);
      if (token != _token) return null;
      _details[leadId] = response;
      if (response['lead'] is Map) {
        final raw = Map<String, dynamic>.from(response['lead'] as Map);
        final parsed = Lead.fromApi(raw);
        final index =
            _leads.indexWhere((l) => l.id == leadId || l.id == parsed.id);
        if (index >= 0) {
          _leads[index] = parsed;
        } else {
          _leads = [parsed, ..._leads];
        }
        _details[parsed.id] = response;
      }
      notifyListeners();
      return response;
    } catch (_) {
      return _details[leadId];
    }
  }

  Future<Lead> updateStatus(String leadId, String newStatus) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    saving = true;
    notifyListeners();
    try {
      final apiStatus = LeadStatus.api(newStatus);
      final updated = await _repository
          .update(token, leadId, {'status': apiStatus}, admin: canManage);
      final index =
          _leads.indexWhere((l) => l.id == leadId || l.id == updated.id);
      if (index >= 0) {
        _leads[index] = updated;
      }
      await fetchDetails(leadId, force: true);
      final account = _session.user?.id ?? 'account';
      await _persist(account, token, _revision);
      notifyListeners();
      return updated;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<Lead> updatePriority(String leadId, String newPriority) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    saving = true;
    notifyListeners();
    try {
      final updated = await _repository.update(
          token,
          leadId,
          {
            'priority':
                newPriority == 'Normal' ? 'medium' : newPriority.toLowerCase()
          },
          admin: canManage);
      final index =
          _leads.indexWhere((l) => l.id == leadId || l.id == updated.id);
      if (index >= 0) {
        _leads[index] = updated;
      }
      await fetchDetails(leadId, force: true);
      final account = _session.user?.id ?? 'account';
      await _persist(account, token, _revision);
      notifyListeners();
      return updated;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String leadId, String body) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    await _repository.addNote(token, leadId, body);
    if (token != _token) return;
    await fetchDetails(leadId, force: true);
    notifyListeners();
  }

  Future<void> uploadAttachment(
    String leadId, {
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    try {
      await _repository.uploadAttachment(
        token,
        leadId,
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      );
      await fetchDetails(leadId, force: true);
      notifyListeners();
    } catch (_) {
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

  Future<Uint8List> downloadAttachment(
      String leadId, String attachmentId) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');
    final bytes =
        await _repository.downloadAttachment(token, leadId, attachmentId);
    if (_token != token) throw const ApiException('Please sign in again.');
    return bytes;
  }
}
