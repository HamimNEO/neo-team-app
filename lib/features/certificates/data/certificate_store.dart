import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../more/data/notification_store.dart';
import '../domain/models/certificate_request.dart';
import 'certificate_api.dart';

class CertificateStore extends FrameSafeNotifier {
  CertificateStore._() {
    _token = _session.accessToken;
    _session.addListener(() {
      if (_token == _session.accessToken) return;
      _token = _session.accessToken;
      _requests = [];
      loading = loaded = false;
      error = null;
      _pending = null;
      notifyListeners();
    });
  }

  static final instance = CertificateStore._();
  final _session = AuthSession.instance;
  late final _api = CertificateApi(ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate));
  final _cache = const PreferencesStore();
  List<CertificateRequest> _requests = [];
  String? _token, error;
  bool loading = false, loaded = false;
  Future<void>? _pending;

  List<CertificateRequest> get allRequests => List.unmodifiable(_requests);

  List<CertificateRequest> requestsForEmployee(String id) =>
      _requests.where((r) => r.employeeId == id).toList();

  CertificateRequest? byId(String id) =>
      _requests.where((r) => r.id == id).firstOrNull;

  int get pendingCount => _requests.where((r) => r.isPending).length;

  int get inPreparationCount =>
      _requests.where((r) => r.isInPreparation).length;

  Future<void> load({bool force = false}) {
    if (_token == null || (loaded && !force)) return Future.value();
    return _pending ??= _load();
  }

  Future<void> _load() async {
    final token = _token!, key = 'nec_certificates_api_v1_${_session.user!.id}';
    final admin = _session.isAdmin;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!loaded) {
        try {
          final raw = await _cache.read(key);
          if (raw != null && token == _token) {
            _requests = (jsonDecode(raw) as List)
                .map((r) =>
                    CertificateRequest.fromApi(Map<String, dynamic>.from(r)))
                .toList();
            notifyListeners();
          }
        } catch (_) {}
      }
      final rows = await _api.list(token, admin);
      if (token != _token) return;
      _requests = rows.map(CertificateRequest.fromApi).toList();
      loaded = true;
      try {
        await _cache.write(key, jsonEncode(rows));
      } catch (_) {}
    } catch (e) {
      if (token == _token) {
        error = e is FormatException
            ? e.message
            : 'Certificates could not be loaded.';
      }
    } finally {
      if (token == _token) {
        loading = false;
        _pending = null;
        notifyListeners();
      }
    }
  }

  CertificateRequest? _apply(Map<String, dynamic> response) {
    final raw =
        response['certificate'] ?? response['request'] ?? response['data'];
    if (raw is! Map || raw['id'] == null) return null;
    final item = CertificateRequest.fromApi(Map<String, dynamic>.from(raw));
    _requests = [item, ..._requests.where((r) => r.id != item.id)];
    notifyListeners();
    return item;
  }

  Future<CertificateRequest> submitRequest(
      {required String employeeId,
      required String employeeName,
      required String employeeCode,
      required String employeeDesignation,
      required String employeeDepartment,
      required String joinedDate,
      required CertificateType type,
      required String purpose,
      String? notes}) async {
    final token = _token;
    if (token == null ||
        employeeId != _session.employeeId ||
        _session.isAdmin) {
      throw const FormatException(
          'Submit this request from your own employee account.');
    }
    final response = await _api.submit(token, {
      'type': switch (type) {
        CertificateType.workExperience => 'experience',
        CertificateType.testimonial => 'testimonial',
        CertificateType.relieving => 'relieving'
      },
      'purpose': purpose,
      if (notes != null) 'notes': notes
    });
    if (token != _token) throw const FormatException('Your account changed.');
    final created = _apply(response);
    await load(force: true);
    NotificationStore.instance.load(filter: 'all', force: true).ignore();
    if (created != null) return byId(created.id) ?? created;
    throw const FormatException(
        'Request accepted by the server. Refresh certificates before submitting again.');
  }

  Future<void> _action(String id, String action,
      {Map<String, dynamic>? body}) async {
    final token = _token;
    if (token == null || !_session.isAdmin) {
      throw const FormatException('Administrator access is required.');
    }
    final response = await _api.action(token, id, action, body: body);
    if (token != _token) return;
    _apply(response);
    await load(force: true);
    NotificationStore.instance.load(filter: 'all', force: true).ignore();
  }

  Future<void> acceptRequest(String id) => _action(id, 'accept');

  Future<void> rejectRequest(String id, String reason) =>
      _action(id, 'reject', body: {'reason': reason.trim()});

  Future<void> deliverCertificate(String id,
      {required String conduct,
      required String keyContributions,
      String? leavingDate,
      required String authorizedSignatory,
      required String signatoryTitle,
      String? certificateNumber,
      ApiUpload? officialSeal,
      ApiUpload? signature}) async {
    final token = _token;
    if (token == null || !_session.isAdmin) {
      throw const FormatException('Administrator access is required.');
    }
    if (certificateNumber == null || certificateNumber.trim().isEmpty) {
      throw const FormatException('Enter a certificate number.');
    }
    final response = await _api.deliver(token, id, {
      'certificate_number': certificateNumber.trim(),
      'conduct': conduct,
      'key_contributions': keyContributions,
      'authorized_signatory_name': authorizedSignatory,
      'authorized_signatory_designation': signatoryTitle,
      'issued_at': DateTime.now().toUtc().toIso8601String(),
      if (leavingDate != null && DateTime.tryParse(leavingDate) != null)
        'leaving_date': leavingDate
    }, [
      if (officialSeal != null) officialSeal,
      if (signature != null) signature
    ]);
    if (token != _token) return;
    _apply(response);
    await load(force: true);
    NotificationStore.instance.load(filter: 'all', force: true).ignore();
  }
}
