import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/storage/file_export.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/audit_entry.dart';
import 'audit_api.dart';

class AuditStore extends FrameSafeNotifier {
  AuditStore._() {
    _token = _session.accessToken;
    _session.addListener(() {
      if (_token == _session.accessToken) return;
      _token = _session.accessToken;
      entries = [];
      error = null;
      loaded = loading = false;
      _pending = null;
      notifyListeners();
    });
  }

  static final instance = AuditStore._();
  final _session = AuthSession.instance;
  late final _api = AuditApi(ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate));
  List<AuditEntry> entries = [];
  String? _token, error;
  bool loaded = false, loading = false;
  Future<void>? _pending;

  AuditEntry? byId(String id) => entries.where((e) => e.id == id).firstOrNull;

  Future<void> load({bool force = false, Map<String, String>? filters}) {
    if (_token == null || (loaded && !force && filters == null)) {
      return Future.value();
    }
    if (_pending != null && force) {
      return _pending!.then((_) => load(force: true, filters: filters));
    }
    return _pending ??= _load(filters);
  }

  Future<void> _load(Map<String, String>? filters) async {
    final token = _token!;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _api.list(token, filters: filters);
      if (token != _token) return;
      entries = rows.map(AuditEntry.fromApi).toList();
      loaded = true;
    } catch (e) {
      if (token == _token) {
        error = e is FormatException
            ? e.message
            : 'Audit logs could not be loaded.';
      }
    } finally {
      if (token == _token) {
        loading = false;
        _pending = null;
        notifyListeners();
      }
    }
  }

  Future<void> detail(String id) async {
    final token = _token;
    if (token == null) return;
    final response = await _api.detail(token, id);
    final raw = response['audit_log'] ??
        response['entry'] ??
        response['data'] ??
        response;
    if (raw is! Map) throw const FormatException('Invalid audit response.');
    if (token != _token) return;
    final item = AuditEntry.fromApi(Map<String, dynamic>.from(raw));
    entries = [item, ...entries.where((e) => e.id != item.id)];
    notifyListeners();
  }

  Future<void> export(
      {String? from, String? to, String? actorId, String? eventType}) async {
    final token = _token;
    if (token == null) throw const FormatException('Please sign in again.');
    final bytes = await _api.client
        .download('${AuditApi.path}/export', token: token, queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (actorId?.isNotEmpty == true) 'actor_id': actorId!,
      if (eventType?.isNotEmpty == true) 'event_type': eventType!
    });
    if (token != _token) return;
    await FileExport.save('team-audit-logs.csv', bytes);
  }
}
