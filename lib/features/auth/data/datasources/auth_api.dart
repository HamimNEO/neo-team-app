import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/auth_session_data.dart';
import '../../domain/models/auth_user.dart';

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSessionData> login(String login, String password) async {
    try {
      final data = await _client.post(ApiEndpoints.login,
          body: {'login': login, 'password': password}, authenticated: false);
      return AuthSessionData.fromJson(data);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        throw const ApiException('Incorrect login or password.',
            statusCode: 401);
      }
      rethrow;
    }
  }

  Future<AuthUser> currentUser(String token) async {
    final data = await _client.get(ApiEndpoints.me, token: token);
    if (data['user'] is! Map) {
      throw const ApiException('The server returned an invalid user.');
    }
    return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<void> changePassword(
      String token, String current, String password) async {
    await _client.post(ApiEndpoints.changePassword, token: token, body: {
      'current_password': current,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<void> signOut(String token) async {
    await _client.post(ApiEndpoints.signOut, token: token, body: {});
  }
}
