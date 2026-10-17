import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'datasources/admin_settings_api.dart';

class AdminSettingsStore extends FrameSafeNotifier {
  AdminSettingsStore._({required AdminSettingsApi api}) : _api = api {
    AuthSession.instance.addListener(_sessionChanged);
  }

  static final AdminSettingsStore instance = _create();

  static AdminSettingsStore _create() {
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => AuthSession.instance.accessToken,
      onUnauthorized: (token) => AuthSession.instance.invalidate(token),
    );
    return AdminSettingsStore._(api: AdminSettingsApi(client));
  }

  final AdminSettingsApi _api;

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _leadSettings;
  Map<String, dynamic>? _operationsSettings;
  Map<String, dynamic>? _systemSettings;
  Map<String, dynamic>? _allSettings;
  Map<String, dynamic>? _summary;
  String? summaryError;
  String? _token;

  Map<String, dynamic>? get summary => _summary;

  void _sessionChanged() {
    if (_token == AuthSession.instance.accessToken) return;
    _token = AuthSession.instance.accessToken;
    _leadSettings =
        _operationsSettings = _systemSettings = _allSettings = _summary = null;
    _error = summaryError = null;
    _isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  String? get error => _error;

  Map<String, dynamic>? get leadSettings => _leadSettings;

  Map<String, dynamic>? get operationsSettings => _operationsSettings;

  Map<String, dynamic>? get systemSettings => _systemSettings;

  Map<String, dynamic>? get allSettings => _allSettings;

  Future<void> loadAll() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return;
    }
    _token = token;

    _isLoading = true;
    _error = null;
    summaryError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getLeadSettings(token).catchError((_) => <String, dynamic>{}),
        _api
            .getOperationsSettings(token)
            .catchError((_) => <String, dynamic>{}),
        _api.getSystemSettings(token).catchError((_) => <String, dynamic>{}),
        _api.getAllSettings(token).catchError((_) => <String, dynamic>{}),
        _api.getAdministrationSummary(token).catchError((Object error) {
          if (token == AuthSession.instance.accessToken) {
            summaryError = error is ApiException
                ? error.message
                : 'Unable to load administration summary.';
          }
          return <String, dynamic>{};
        }),
      ]);
      if (token != AuthSession.instance.accessToken) return;
      _leadSettings = results[0];
      _operationsSettings = results[1];
      _systemSettings = results[2];
      _allSettings = results[3];
      if (summaryError == null) _summary = results[4];
    } catch (e) {
      if (token == AuthSession.instance.accessToken) _error = e.toString();
    } finally {
      if (token == AuthSession.instance.accessToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createLeadSource({
    required String key,
    required String label,
    String? color,
  }) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return false;
    }

    try {
      await _api.createLeadSource(token, key: key, label: label, color: color);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createCustomField(Map<String, dynamic> body) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return false;
    }

    try {
      await _api.createCustomField(token, body);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateSetting({
    required String group,
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return false;
    }

    try {
      await _api.updateSetting(token, group: group, key: key, value: value);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disableLeadSource(String key, bool active) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return false;
    }

    try {
      await _api.disableLeadSource(token, key, active: active);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCustomSetting({
    required String group,
    required String key,
  }) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !StaffAccessStore.instance.canManageAdministration) {
      return false;
    }

    try {
      await _api.deleteCustomSetting(token, group: group, key: key);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }
}
