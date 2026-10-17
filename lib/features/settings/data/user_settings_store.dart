import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'datasources/user_settings_api.dart';

class UserSettingsStore extends FrameSafeNotifier {
  UserSettingsStore._({required UserSettingsApi api}) : _api = api;

  static final UserSettingsStore instance = _create();

  static const String _keyDefaultView = 'nec_pref_default_view_v1';
  static const String _keyHaptic = 'nec_pref_haptic_feedback_v1';
  static const String _keyReduceMotion = 'nec_pref_reduce_motion_v1';

  static UserSettingsStore _create() {
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => AuthSession.instance.accessToken,
      onUnauthorized: (token) => AuthSession.instance.invalidate(token),
    );
    return UserSettingsStore._(api: UserSettingsApi(client));
  }

  final UserSettingsApi _api;

  bool _isLoading = false;
  String? _error;

  String _appearance = 'light';
  String _language = 'en';
  String _defaultView = 'home';
  bool _hapticFeedback = true;
  bool _reduceMotion = false;
  Map<String, String> _devicePermissions = {};
  Map<String, dynamic>? _accountSecurity;

  bool get isLoading => _isLoading;

  String? get error => _error;

  String get appearance => _appearance;

  String get language => _language;

  String get defaultView => _defaultView;

  String get defaultViewTitle {
    switch (_defaultView.toLowerCase()) {
      case 'leads':
        return 'Leads';
      case 'tasks':
        return 'Tasks';
      case 'messages':
        return 'Messages';
      case 'attendance':
        return 'Attendance';
      case 'more':
        return 'More';
      default:
        return 'Home';
    }
  }

  String get defaultViewRoute {
    switch (_defaultView.toLowerCase()) {
      case 'leads':
        return '/leads';
      case 'tasks':
        return '/tasks';
      case 'messages':
        return '/messages';
      case 'attendance':
        return '/attendance';
      case 'more':
        return '/more';
      default:
        return '/home';
    }
  }

  bool get hapticFeedback => _hapticFeedback;

  bool get reduceMotion => _reduceMotion;

  Map<String, String> get devicePermissions =>
      Map.unmodifiable(_devicePermissions);

  Map<String, dynamic>? get accountSecurity => _accountSecurity;

  /// Restores cached local preferences immediately before network call.
  Future<void> restoreCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultView = prefs.getString(_keyDefaultView) ?? _defaultView;
      _hapticFeedback = prefs.getBool(_keyHaptic) ?? _hapticFeedback;
      _reduceMotion = prefs.getBool(_keyReduceMotion) ?? _reduceMotion;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> load() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !AuthSession.instance.signedIn) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getSettings(token);
      final settings = res['settings'];
      if (settings is Map) {
        _appearance = settings['appearance']?.toString() ?? _appearance;
        _language = settings['language']?.toString() ?? _language;
        _defaultView = settings['default_view']?.toString() ?? _defaultView;
        if (settings['haptic_feedback'] is bool) {
          _hapticFeedback = settings['haptic_feedback'] as bool;
        }
        if (settings['reduce_motion'] is bool) {
          _reduceMotion = settings['reduce_motion'] as bool;
        }
        final perms = settings['device_permissions'];
        if (perms is Map) {
          _devicePermissions =
              perms.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDefaultView, _defaultView);
        await prefs.setBool(_keyHaptic, _hapticFeedback);
        await prefs.setBool(_keyReduceMotion, _reduceMotion);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAccountSecurity() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !AuthSession.instance.signedIn) return;

    try {
      _accountSecurity = await _api.getAccountSecurity(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateSettings({
    String? appearance,
    String? language,
    String? defaultView,
    bool? hapticFeedback,
    bool? reduceMotion,
    Map<String, String>? devicePermissions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (appearance != null) _appearance = appearance;
      if (language != null) _language = language;
      if (defaultView != null) {
        _defaultView = defaultView;
        await prefs.setString(_keyDefaultView, defaultView);
      }
      if (hapticFeedback != null) {
        _hapticFeedback = hapticFeedback;
        await prefs.setBool(_keyHaptic, hapticFeedback);
      }
      if (reduceMotion != null) {
        _reduceMotion = reduceMotion;
        await prefs.setBool(_keyReduceMotion, reduceMotion);
      }
      if (devicePermissions != null) _devicePermissions = devicePermissions;
    } catch (_) {}

    notifyListeners();

    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    final body = <String, dynamic>{
      'appearance': _appearance,
      'language': _language,
      'default_view': _defaultView,
      'haptic_feedback': _hapticFeedback,
      'reduce_motion': _reduceMotion,
      'device_permissions': _devicePermissions,
    };

    try {
      await _api.updateSettings(token, body);
    } catch (_) {}
  }
}
