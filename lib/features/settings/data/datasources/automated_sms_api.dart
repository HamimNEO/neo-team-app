import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AutomatedSmsApi {
  const AutomatedSmsApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> load(String token) =>
      _client.get(ApiEndpoints.automatedSms, token: token);

  Future<Map<String, dynamic>> save(String token, Map<String, dynamic> body) =>
      _client.put(ApiEndpoints.automatedSms, token: token, body: body);

  Future<Map<String, dynamic>> test(String token, String phone) =>
      _client.post('${ApiEndpoints.automatedSms}/test',
          token: token, body: {'phone': phone});
}
