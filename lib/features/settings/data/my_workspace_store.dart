import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_api_mapper.dart';
import '../../team/domain/models/employee.dart';

/// Employee-scoped unit responses; never derives membership from name matches.
class MyWorkspaceStore extends FrameSafeNotifier {
  MyWorkspaceStore._() {
    _token = _session.accessToken;
    _session.addListener(() {
      if (_token == _session.accessToken) return;
      _token = _session.accessToken;
      department = {};
      team = {};
      departmentMembers = [];
      teamMembers = [];
      _loading = null;
      loading = loaded = false;
      error = null;
      notifyListeners();
    });
  }

  static final instance = MyWorkspaceStore._();
  final _session = AuthSession.instance;
  late final _api = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate);
  final _cache = const PreferencesStore();
  String? _token, error;
  bool loading = false, loaded = false;
  Future<void>? _loading;
  Map<String, dynamic> department = {}, team = {};
  List<Employee> departmentMembers = [], teamMembers = [];

  Map<String, dynamic> _publicMap(Map value) => {
        for (final entry in value.entries)
          if (!['salary', 'salary_enabled', 'access', 'permissions']
              .contains(entry.key))
            entry.key.toString(): entry.value is Map
                ? _publicMap(entry.value as Map)
                : entry.value is List
                    ? [
                        for (final item in entry.value as List)
                          if (item is Map) _publicMap(item) else item
                      ]
                    : entry.value,
      };

  void _apply(Map<String, dynamic> data) {
    final dept = data['department_response'] as Map? ?? {};
    final group = data['team_response'] as Map? ?? {};
    department = Map<String, dynamic>.from(dept['department'] as Map? ?? {});
    team = Map<String, dynamic>.from(group['team'] as Map? ?? {});
    List<Employee> members(Map response) => [
          for (final raw in response['members'] as List? ?? [])
            if (raw is Map)
              employeeFromApi(_publicMap(raw), AppConfig.apiBaseUrl),
        ];
    departmentMembers = members(dept);
    teamMembers = members(group);
    loaded = true;
  }

  Future<void> load({bool force = false}) {
    if (_token == null || _session.isAdmin || (!force && loaded)) {
      return Future.value();
    }
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final token = _token!, key = 'nec_my_workspace_v1_${_session.user!.id}';
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!loaded) {
        try {
          final raw = await _cache.read(key);
          if (raw != null && token == _token) {
            _apply(Map<String, dynamic>.from(jsonDecode(raw)));
            notifyListeners();
          }
        } catch (_) {}
      }
      final values = await Future.wait([
        _api.get(ApiEndpoints.myDepartment, token: token),
        _api.get(ApiEndpoints.myTeam, token: token),
      ]);
      if (token != _token) return;
      final data = _publicMap(
          {'department_response': values[0], 'team_response': values[1]});
      _apply(data);
      try {
        await _cache.write(key, jsonEncode(data));
      } catch (_) {}
    } catch (_) {
      if (token == _token) {
        error = 'Your workspace could not be refreshed. Please try again.';
      }
    } finally {
      if (token == _token) {
        loading = false;
        _loading = null;
        notifyListeners();
      }
    }
  }
}
