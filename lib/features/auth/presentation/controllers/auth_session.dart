import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/preferences_store.dart';
import '../../data/datasources/auth_api.dart';
import '../../data/datasources/auth_session_cache.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/auth_session_data.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth state consumed by the existing UI. No local credentials grant access.
class AuthSession extends ChangeNotifier {
  AuthSession({required AuthRepository repository}) : _repository = repository;

  static final instance = _create();

  static AuthSession _create() {
    late AuthSession session;
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => session.accessToken,
      onUnauthorized: (token) => session.invalidate(token),
    );
    session = AuthSession(
        repository: AuthRepositoryImpl(
      api: AuthApi(client),
      cache: const AuthSessionCache(PreferencesStore()),
    ));
    return session;
  }

  static const adminEmployeeId = 'emp_mahmud';
  static const staffEmployeeId = 'emp_shahina';

  static String get adminEmail => AppConfig.adminLoginId.toLowerCase();

  static String normalizeLoginEmail(String email) => email.trim().toLowerCase();

  final AuthRepository _repository;
  AuthSessionData? _session;
  Timer? _expiryTimer;
  int _generation = 0;
  Future<void> _pendingStorage = Future.value();
  String? restoreError;
  Future<void> Function(String token)? beforeSignOut;

  bool get signedIn => _session != null && !_session!.isExpired;

  bool get isAdmin => signedIn && _session!.user.isSuperAdmin;

  String get roleLabel => isAdmin ? 'Admin' : 'Staff';

  AuthUser? get user => signedIn ? _session!.user : null;

  String get email => user?.email ?? '';

  String? get accessToken => signedIn ? _session!.token : null;

  bool get mustChangePassword => user?.mustChangePassword ?? false;

  String get employeeId => isAdmin
      ? adminEmployeeId
      : user == null
          ? staffEmployeeId
          : 'api_emp_${user!.employeeId}';

  Future<void> _store(Future<void> Function() action) {
    final result = _pendingStorage.then((_) => action());
    _pendingStorage =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> load({bool verifyInBackground = false}) async {
    final generation = ++_generation;
    _session = null;
    _expiryTimer?.cancel();
    restoreError = null;
    try {
      var cached = await _repository.readSession();
      if (cached == null || cached.isExpired) return;
      if (verifyInBackground) {
        if (generation != _generation) return;
        _activate(cached);
        unawaited(_verifyRestoredSession(cached, generation));
        return;
      }
      try {
        final user = await _repository.currentUser(cached.token);
        cached = cached.withUser(user);
        await _store(() async {
          if (generation == _generation) await _repository.saveSession(cached!);
        });
      } on ApiException catch (error) {
        if (error.isUnauthorized || error.statusCode == 403) {
          await _store(() async {
            if (generation == _generation) await _repository.clearSession();
          });
          return;
        }
        restoreError = error.message;
      }
      final restored = cached;
      if (generation == _generation &&
          restored != null &&
          !restored.isExpired) {
        _activate(restored);
      }
    } catch (_) {
      restoreError = 'Unable to restore your session. Please sign in again.';
      if (generation == _generation) {
        _session = null;
        _expiryTimer?.cancel();
        notifyListeners();
      }
    }
  }

  Future<void> _verifyRestoredSession(
      AuthSessionData cached, int generation) async {
    bool current() => generation == _generation && _session == cached;
    try {
      final user = await _repository.currentUser(cached.token);
      if (!current()) return;
      final verified = cached.withUser(user);
      await _store(() async {
        if (current()) await _repository.saveSession(verified);
      });
      if (current() && !verified.isExpired) _activate(verified);
    } on ApiException catch (error) {
      if (!current()) return;
      if (error.isUnauthorized || error.statusCode == 403) {
        await invalidate(cached.token);
      } else {
        restoreError = error.message;
      }
    } catch (_) {
      if (current()) restoreError = 'Unable to verify your saved session.';
    }
  }

  Future<void> signIn(String login, String password) async {
    if (login.trim().isEmpty || password.isEmpty) {
      throw const FormatException('Please enter your email and password.');
    }
    final generation = ++_generation;
    final session = await _repository.login(login.trim(), password);
    if (session.isExpired) {
      throw const FormatException(
          'The server returned an expired session. Please try again.');
    }
    await _store(() async {
      if (generation != _generation) {
        throw const FormatException(
            'This sign-in was cancelled. Please try again.');
      }
      await _repository.saveSession(session);
    });
    if (generation != _generation) {
      throw const FormatException(
          'This sign-in was cancelled. Please try again.');
    }
    restoreError = null;
    _activate(session);
  }

  void _activate(AuthSessionData session) {
    _session = session;
    _expiryTimer?.cancel();
    _expiryTimer = Timer(session.expiresAt.difference(DateTime.now()), () {
      unawaited(invalidate(session.token).catchError((Object _) {
        restoreError = 'Unable to clear the expired session.';
      }));
    });
    notifyListeners();
  }

  /// Token matching prevents a late 401 from clearing a newer login.
  Future<void> invalidate(String rejectedToken) async {
    if (_session?.token != rejectedToken) return;
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    ++_generation;
    _session = null;
    _expiryTimer?.cancel();
    notifyListeners();
    await _store(_repository.clearSession);
    await const PreferencesStore().removeByPrefixes([
      'nec_leads_',
      'nec_work_items_api_',
      'nec_work_overview_api_',
      'nec_attendance_api_',
      'nec_lunch_api_',
      'nec_my_workspace_',
      'nec_auto_sms_api_',
    ]);
  }

  Future<void> signOut() async {
    final token = _session?.token;
    if (token != null && beforeSignOut != null) {
      try {
        await beforeSignOut!(token);
      } catch (_) {}
    }
    await _clearLocalSession();
    if (token == null) return;
    try {
      await _repository.signOut(token);
    } on ApiException catch (error) {
      if (!error.isUnauthorized) restoreError = error.message;
    }
  }

  Future<void> verifyPassword(String password) async {
    final active = _session;
    if (!signedIn || active == null) {
      throw const FormatException('Please sign in again.');
    }
    final verified = await _repository.login(active.user.email, password);
    await _repository.signOut(verified.token);
    if (_session != active || verified.user.id != active.user.id) {
      throw const FormatException('The account changed. Please sign in again.');
    }
  }

  Future<void> changePassword(String current, String password) async {
    final active = _session;
    if (!signedIn || active == null) {
      throw const FormatException('Please sign in again.');
    }
    await _repository.changePassword(active.token, current, password);
    if (_session != active) return;
    final updated =
        active.withUser(await _repository.currentUser(active.token));
    await _store(() async {
      if (_session == active) await _repository.saveSession(updated);
    });
    if (_session == active) _activate(updated);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
