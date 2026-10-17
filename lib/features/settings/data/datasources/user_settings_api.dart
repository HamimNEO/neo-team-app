import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class UserSettingsApi {
  const UserSettingsApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getSettings(String token) async {
    final response = await _client.get(
      ApiEndpoints.userSettings,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> updateSettings(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      ApiEndpoints.userSettings,
      token: token,
      body: body,
    );
    return response;
  }

  Future<Map<String, dynamic>> getAccountSecurity(String token) async {
    final response = await _client.get(
      ApiEndpoints.accountSecurity,
      token: token,
    );
    return response;
  }
}
