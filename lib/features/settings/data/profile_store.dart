import '../../../core/notifiers/frame_safe_notifier.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../domain/models/account_profile.dart';
import 'datasources/profile_api.dart';
import 'datasources/profile_cache.dart';
import 'repositories/profile_repository.dart';

class ProfileStore extends FrameSafeNotifier {
  ProfileStore(
      {required AuthSession session, required ProfileRepository repository})
      : _session = session,
        _repository = repository {
    _session.addListener(_sessionChanged);
  }

  static final instance = _create();

  static ProfileStore _create() {
    final session = AuthSession.instance;
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => session.accessToken,
      onUnauthorized: session.invalidate,
    );
    return ProfileStore(
        session: session,
        repository: ProfileRepository(
          api: ProfileApi(client),
          cache: const ProfileCache(PreferencesStore()),
        ));
  }

  final AuthSession _session;
  final ProfileRepository _repository;
  AccountProfile? _profile;
  String? _token;
  Future<void>? _loading;
  String? loadError;
  bool saving = false;

  bool get loading => _loading != null;

  AccountProfile? get profile =>
      _profile?.id == _session.user?.id ? _profile : null;

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _profile = null;
    _loading = null;
    loadError = null;
    saving = false;
    notifyListeners();
  }

  Future<void> load() {
    _sessionChanged();
    if (_session.accessToken == null || saving) return Future.value();
    return _loading ??= _load();
  }

  void _apply(AccountProfile value) {
    final employee = value.employeeProfile;
    if (!_session.isAdmin &&
        employee != null &&
        employee.id != _session.employeeId) {
      throw const FormatException(
          'The server returned a different employee profile.');
    }
    final previous = _profile?.employeeProfile;
    if (employee?.photoUrl != null &&
        employee!.photoUrl == previous?.photoUrl &&
        employee.photoBase64 == null &&
        previous?.photoBase64 != null) {
      value = AccountProfile.fromJson({
        ...value.toJson(),
        'employee_profile': {
          ...employee.toJson(),
          'photoBase64': previous!.photoBase64
        },
      });
    }
    _profile = value;
    if (value.employeeProfile != null) {
      EmployeeStore.instance.applyCurrentProfile(value.employeeProfile!);
    }
    notifyListeners();
  }

  Future<void> updatePersonal(Employee employee,
      {bool photoChanged = false}) async {
    final token = _session.accessToken, userId = _session.user?.id;
    if (token == null ||
        userId == null ||
        _session.isAdmin ||
        employee.id != _session.employeeId) {
      throw const FormatException(
          'Only the signed-in employee can edit this profile.');
    }
    if (saving) {
      throw const FormatException('A profile update is already in progress.');
    }
    saving = true;
    notifyListeners();
    bool current() =>
        _session.accessToken == token && _session.user?.id == userId;
    try {
      await _loading;
      if (!current()) {
        throw const FormatException(
            'Your account changed. Reopen Edit Profile.');
      }
      final fresh = await _repository.update(token, employee,
          photo: photoChanged ? employee.photoBase64 : null);
      if (!current()) return;
      if (fresh.id != userId) {
        throw const FormatException(
            'The server returned a different account profile.');
      }
      _apply(fresh);
      loadError = null;
      try {
        await _repository.saveCache(fresh);
      } catch (_) {
        loadError =
            'Profile saved, but its offline cache could not be updated.';
      }
    } finally {
      if (current()) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> _load() async {
    final token = _session.accessToken;
    final userId = _session.user?.id;
    if (token == null || userId == null) return;
    notifyListeners();
    bool stillCurrent() =>
        _session.accessToken == token && _session.user?.id == userId;
    try {
      final cached = await _repository.readCache(userId);
      if (!stillCurrent()) return;
      if (cached != null) {
        _apply(cached);
      }
    } catch (_) {
      // A failed cache read must not prevent a fresh API fetch.
    }
    try {
      final fresh = await _repository.fetch(token);
      if (!stillCurrent()) return;
      if (fresh.id != userId) {
        throw const FormatException(
            'The server returned a different account profile.');
      }
      _apply(fresh);
      loadError = null;
      notifyListeners();
      try {
        await _repository.saveCache(_profile!);
      } catch (_) {
        // A cache failure must not hide the freshly loaded backend profile.
      }
    } catch (error) {
      if (!stillCurrent()) return;
      loadError = error is FormatException
          ? error.message
          : 'Unable to load your profile. Please try again.';
      notifyListeners();
    } finally {
      if (stillCurrent()) {
        _loading = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }
}
