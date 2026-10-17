import '../../domain/models/auth_session_data.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api.dart';
import '../datasources/auth_session_cache.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
      {required AuthApi api, required AuthSessionCache cache})
      : _api = api,
        _cache = cache;

  final AuthApi _api;
  final AuthSessionCache _cache;

  @override
  Future<AuthSessionData> login(String login, String password) =>
      _api.login(login, password);

  @override
  Future<AuthUser> currentUser(String token) => _api.currentUser(token);

  @override
  Future<void> changePassword(String token, String current, String password) =>
      _api.changePassword(token, current, password);

  @override
  Future<void> signOut(String token) => _api.signOut(token);

  @override
  Future<AuthSessionData?> readSession() => _cache.read();

  @override
  Future<void> saveSession(AuthSessionData session) => _cache.save(session);

  @override
  Future<void> clearSession() => _cache.clear();
}
