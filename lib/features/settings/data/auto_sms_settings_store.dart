import 'dart:async';
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'datasources/automated_sms_api.dart';

class AutoSmsSettingsStore extends FrameSafeNotifier {
  AutoSmsSettingsStore._() {
    _token = _session.accessToken;
    _session.addListener(() {
      if (_token == _session.accessToken) return;
      _token = _session.accessToken;
      _templateTimer?.cancel();
      _ready = loading = saving = false;
      _loadFuture = null;
      error = null;
      _confirmed = null;
      _enabled = false;
      _template = '';
      _preview = '';
      _sender = '';
      _totalDispatched = null;
      _testPhoneNumber = '';
      notifyListeners();
    });
  }

  static final instance = AutoSmsSettingsStore._();
  final _session = AuthSession.instance;
  late final _api = AutomatedSmsApi(ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate));
  final _cache = const PreferencesStore();
  String? _token, error;
  bool _ready = false, loading = false, saving = false, _enabled = false;
  String _timing = '15_minutes_before',
      _target = 'client_contact',
      _template = '',
      _sender = '',
      _preview = '',
      _testPhoneNumber = '';
  int? _totalDispatched;
  Map<String, dynamic>? _confirmed;
  Future<void>? _loadFuture;
  Future<void> _writes = Future.value();
  Timer? _templateTimer;
  int _revision = 0;

  bool get ready => _ready;

  bool get isAutoSmsEnabled => _enabled;

  String get targetValue => _target;

  String get timingValue => _timing;

  String get triggerTiming =>
      _timings.entries.where((e) => e.value == _timing).firstOrNull?.key ??
      _timing;

  String get recipientTarget =>
      _targets.entries.where((e) => e.value == _target).firstOrNull?.key ??
      _target;

  String get senderId => _sender.isEmpty ? 'Not provided' : _sender;

  String get smsTemplate => _template;

  String get preview => _preview;

  String get testPhoneNumber => _testPhoneNumber;

  int? get totalDispatched => _totalDispatched;

  bool get canManage =>
      _session.isAdmin || StaffAccessStore.instance.canManageAdministration;
  static const _timings = {
    'Immediately on creation': 'immediately',
    '15 minutes before': '15_minutes_before',
    '30 minutes before': '30_minutes_before',
    '1 hour before': '1_hour_before',
    'On scheduled time': 'scheduled_time'
  };
  static const _targets = {
    'Client Contact': 'client_contact',
    'Assigned Representative': 'assigned_representative',
    'Both (Client & Rep)': 'both'
  };
  static const timingOptions = [
    'Immediately on creation',
    '15 minutes before',
    '30 minutes before',
    '1 hour before',
    'On scheduled time'
  ];
  static const recipientOptions = [
    'Client Contact',
    'Assigned Representative',
    'Both (Client & Rep)'
  ];
  static const availableTokens = [
    '{{client_name}}',
    '{{date}}',
    '{{time}}',
    '{{purpose}}',
    '{{meeting_link}}',
    '{{rep_name}}',
    '{{company}}'
  ];

  Map<String, dynamic> get _payload => {
        'enabled': _enabled,
        'target': _target,
        'dispatch_timing': _timing,
        'template': _template
      };

  void _apply(Map<String, dynamic> data) {
    final setting = data['setting'] is Map
        ? Map<String, dynamic>.from(data['setting'] as Map)
        : data;
    _enabled = setting['enabled'] == true;
    _timing = setting['dispatch_timing']?.toString() ?? '15_minutes_before';
    _target = setting['target']?.toString() ?? 'client_contact';
    _template = setting['template']?.toString() ?? '';
    _sender = setting['sender_id']?.toString() ?? '';
    _preview = data['preview']?.toString() ?? '';
    _totalDispatched = (data['total_dispatched'] as num?)?.toInt();
    _confirmed = Map.of(_payload);
  }

  Future<void> load({bool force = false}) {
    if (_token == null || !canManage || (_ready && !force)) {
      return Future.value();
    }
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final token = _token!, key = 'nec_auto_sms_api_v1_${_session.user!.id}';
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!_ready) {
        try {
          final raw = await _cache.read(key);
          if (raw != null && token == _token) {
            _apply(Map<String, dynamic>.from(jsonDecode(raw)));
            notifyListeners();
          }
        } catch (_) {}
      }
      final data = await _api.load(token);
      if (token != _token) return;
      _apply(data);
      _ready = true;
      try {
        await _cache.write(key, jsonEncode(data));
      } catch (_) {}
    } catch (e) {
      if (token == _token) {
        error = e is FormatException
            ? e.message
            : 'Unable to load Auto-SMS settings.';
      }
    } finally {
      if (token == _token) {
        loading = false;
        _loadFuture = null;
        notifyListeners();
      }
    }
  }

  void _save() {
    _templateTimer?.cancel();
    if (!canManage || !_ready) return;
    final token = _token!,
        payload = Map<String, dynamic>.of(_payload),
        revision = ++_revision;
    saving = true;
    error = null;
    notifyListeners();
    _writes = _writes.then((_) async {
      if (token != _token) return;
      try {
        final response = await _api.save(token, payload);
        if (token != _token) return;
        _confirmed = payload;
        if (revision == _revision) {
          if (response['setting'] is Map) _apply(response);
          if (response['preview'] is! String) await load(force: true);
        }
      } catch (e) {
        if (token == _token && revision == _revision) {
          if (_confirmed != null) _apply(_confirmed!);
          error = e is FormatException
              ? e.message
              : 'Unable to save Auto-SMS settings.';
        }
      } finally {
        if (token == _token && revision == _revision) {
          saving = false;
          notifyListeners();
        }
      }
    });
  }

  void toggleAutoSms(bool value) {
    if (!canManage) return;
    _enabled = value;
    _save();
  }

  void setTriggerTiming(String value) {
    if (!canManage) return;
    _timing = _timings[value] ?? _timing;
    _save();
  }

  void setRecipientTarget(String value) {
    if (!canManage) return;
    _target = _targets[value] ?? _target;
    _save();
  }

  void setTemplate(String value) {
    if (!canManage) return;
    _template = value;
    _revision++;
    _templateTimer?.cancel();
    _templateTimer = Timer(const Duration(milliseconds: 700), _save);
  }

  void setTestPhoneNumber(String phone) {
    _testPhoneNumber = phone;
  }

  void resetToDefaultTemplate() {
    _templateTimer?.cancel();
    _template = _confirmed?['template']?.toString() ?? '';
    notifyListeners();
  }

  Future<String> sendTestSms(String phone) async {
    if (!canManage || _token == null) {
      throw const ApiException('Administrator access is required.');
    }
    _templateTimer?.cancel();
    if (_confirmed?['template'] != _template) _save();
    await _writes;
    if (error != null) throw ApiException(error!);
    final token = _token!;
    final response =
        await _api.test(token, phone.replaceAll(RegExp(r'\s+'), ''));
    if (token != _token) throw const ApiException('Your account changed.');
    if (response['success'] == false ||
        response['sent'] == false ||
        response['status'] == 'failed') {
      throw ApiException(response['message']?.toString() ??
          'The SMS provider rejected this request.');
    }
    return response['message']?.toString() ?? 'Test SMS request accepted';
  }

  String formatTemplate(
      {required String clientName,
      required String date,
      required String time,
      required String purpose,
      required String repName,
      String meetingLink = ''}) {
    var result = _template;
    final values = {
      'client_name': clientName,
      'date': date,
      'time': time,
      'purpose': purpose,
      'rep_name': repName,
      'company': 'BinGi',
      'meeting_link': meetingLink
    };
    for (final entry in values.entries) {
      result = result
          .replaceAll('{{${entry.key}}}', entry.value)
          .replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
