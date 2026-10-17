import 'dart:convert';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/team_group.dart';
import 'employee_store.dart';
import 'datasources/team_api.dart';
import 'datasources/team_cache.dart';
import 'repositories/team_repository.dart';

class TeamStore extends FrameSafeNotifier {
  TeamStore(
      {required AuthSession session,
      required EmployeeStore employees,
      required TeamRepository repository})
      : _session = session,
        _employees = employees,
        _repository = repository {
    _token = session.accessToken;
    session.addListener(_sessionChanged);
    employees.addListener(_employeesChanged);
  }

  static final instance = _create();

  static TeamStore _create() {
    final session = AuthSession.instance;
    return TeamStore(
        session: session,
        employees: EmployeeStore.instance,
        repository: TeamRepository(
            api: TeamApi(ApiClient(
                baseUrl: () => AppConfig.apiBaseUrl,
                accessToken: () => session.accessToken,
                onUnauthorized: session.invalidate)),
            cache: const TeamCache(PreferencesStore()),
            baseUrl: () => AppConfig.apiBaseUrl));
  }

  final AuthSession _session;
  final EmployeeStore _employees;
  final TeamRepository _repository;
  String? _token, error, cacheError;
  String _fingerprint = '';
  int _revision = 0;
  List<TeamGroup> _teams = [];
  final Map<String, TeamDetail> _details = {};
  bool loading = false, hasData = false, saving = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();

  List<TeamGroup> get teams => List.unmodifiable(_teams);

  TeamDetail? detailFor(String name) => _details[name];

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _revision++;
    _teams = [];
    _details.clear();
    _fingerprint = '';
    _loading = null;
    loading = hasData = saving = false;
    error = cacheError = null;
    notifyListeners();
  }

  void _employeesChanged() {
    if (_token == null || !_employees.hasData) return;
    final fingerprint = jsonEncode(_employees.employees
        .map((e) => [
              e.id,
              e.name,
              e.team,
              e.department,
              e.status,
              e.designation,
              e.phone,
              e.photoUrl,
              e.reportsToId
            ])
        .toList());
    if (fingerprint == _fingerprint) return;
    _fingerprint = fingerprint;
    _revision++;
    _loading = null;
    _details.clear();
    load();
  }

  Future<void> load() => _token == null ? Future.value() : _loading ??= _load();

  Future<void> _load() async {
    final token = _token!,
        account = _session.user!.id,
        admin = _session.isAdmin;
    final revision = _revision;
    bool current() => token == _token && revision == _revision;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!hasData) {
        try {
          final cached = await _repository.cache.read(account, admin);
          if (!current()) return;
          if (cached != null) {
            _teams = cached;
            hasData = true;
            notifyListeners();
          }
        } catch (_) {
          /* Cache must not prevent network loading. */
        }
      }
      final fresh = await _repository.list(token);
      if (!current()) return;
      _teams = fresh;
      hasData = true;
      await _cache(
          token, revision, () => _repository.cache.save(account, admin, fresh));
    } catch (e) {
      if (current()) error = EmployeeStore.messageFor(e);
    } finally {
      if (current()) {
        loading = false;
        _loading = null;
        notifyListeners();
      }
    }
  }

  Future<TeamDetail> details(String name) async {
    final token = _token;
    if (token == null) throw const FormatException('Please sign in again.');
    final revision = _revision,
        account = _session.user!.id,
        admin = _session.isAdmin;
    bool current() => token == _token && revision == _revision;
    if (!_details.containsKey(name)) {
      try {
        final cached = await _repository.cache.readDetail(account, admin, name);
        if (current() && cached != null) {
          _details[name] = cached;
          notifyListeners();
        }
      } catch (_) {
        /* Use the network when cache is unavailable. */
      }
    }
    final resourceId = _details[name]?.team.backendId ??
        _teams
            .where((team) => team.name == name || team.backendId == name)
            .firstOrNull
            ?.backendId ??
        name;
    final fresh = await _repository.details(token, resourceId);
    if (!current()) {
      throw const FormatException('Team data changed. Please refresh.');
    }
    _details[name] = fresh;
    _details[fresh.team.name] = fresh;
    if (fresh.team.backendId != null) _details[fresh.team.backendId!] = fresh;
    await _cache(token, revision,
        () => _repository.cache.saveDetail(account, admin, fresh));
    notifyListeners();
    return fresh;
  }

  Future<TeamGroup> create(
      {required String name,
      String? departmentId,
      String? leadId,
      String? description}) async {
    if (!_session.isAdmin || _token == null) {
      throw const FormatException('Administrator access is required.');
    }
    if (saving) {
      throw const FormatException('A team change is already in progress.');
    }
    if (name.trim().isEmpty) throw const FormatException('Enter a team name.');
    final token = _token!, account = _session.user!.id;
    final revision = ++_revision;
    _loading = null;
    loading = false;
    saving = true;
    notifyListeners();
    try {
      final team = await _repository.create(token, {
        'name': name.trim(),
        if (departmentId != null) 'department_id': int.parse(departmentId),
        if (leadId != null)
          'lead_id': int.parse(leadId.replaceFirst('api_emp_', '')),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      });
      if (token != _token || revision != _revision) {
        throw const FormatException(
            'Your session changed. Refresh the team list.');
      }
      _teams = [..._teams.where((item) => item.name != team.name), team];
      error = null;
      await _cache(token, revision,
          () => _repository.cache.save(account, _session.isAdmin, _teams));
      return team;
    } finally {
      if (token == _token && revision == _revision) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> delete(TeamGroup team) async {
    if (!_session.isAdmin || _token == null || team.backendId == null) {
      throw const FormatException(
          'Administrator access and a saved team are required.');
    }
    if (saving) {
      throw const FormatException('A team change is already in progress.');
    }
    final token = _token!, account = _session.user!.id;
    final revision = ++_revision;
    _loading = null;
    loading = false;
    saving = true;
    notifyListeners();
    try {
      await _repository.delete(token, team.backendId!);
      if (token != _token || revision != _revision) {
        throw const FormatException(
            'Your session changed. Refresh the team list.');
      }
      _teams =
          _teams.where((item) => item.backendId != team.backendId).toList();
      _details
          .removeWhere((_, detail) => detail.team.backendId == team.backendId);
      await _cache(token, revision, () async {
        await _repository.cache.save(account, _session.isAdmin, _teams);
        await _repository.cache
            .removeDetail(account, _session.isAdmin, team.name);
      });
    } finally {
      if (token == _token && revision == _revision) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<TeamDetail> update(TeamGroup team, Map<String, dynamic> body) async {
    final token = _token, revision = _revision;
    if (!_session.isAdmin ||
        token == null ||
        team.backendId == null ||
        saving) {
      throw const FormatException(
          'Administrator access to this team is required.');
    }
    saving = true;
    notifyListeners();
    try {
      final detail = await _repository.update(token, team.backendId!, body);
      if (token != _token || revision != _revision) {
        throw const FormatException('Your account changed.');
      }
      _details
          .removeWhere((_, value) => value.team.backendId == team.backendId);
      _details[detail.team.name] = detail;
      _details[team.backendId!] = detail;
      _details[team.name] = detail;
      _teams = [
        for (final item in _teams)
          if (item.backendId == team.backendId) detail.team else item
      ];
      await _cache(token, revision, () async {
        await _repository.cache.save(_session.user!.id, true, _teams);
        await _repository.cache
            .removeDetail(_session.user!.id, true, team.name);
      });
      return detail;
    } finally {
      if (token == _token) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> _cache(
      String token, int revision, Future<void> Function() write) {
    _writes = _writes.then((_) async {
      if (token != _token || revision != _revision) return;
      try {
        await write();
        if (token == _token && revision == _revision) cacheError = null;
      } catch (_) {
        if (token == _token && revision == _revision) {
          cacheError = 'Team offline cache could not be updated.';
        }
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    _employees.removeListener(_employeesChanged);
    super.dispose();
  }
}
