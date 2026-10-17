import '../models/auth_session_data.dart';
import '../models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthSessionData> login(String login, String password);

  Future<AuthUser> currentUser(String token);

  Future<void> changePassword(String token, String current, String password);

  Future<void> signOut(String token);

  Future<AuthSessionData?> readSession();

  Future<void> saveSession(AuthSessionData session);

  Future<void> clearSession();
}
