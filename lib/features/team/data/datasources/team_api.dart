import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';

class TeamApi {
  const TeamApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> update(
          String token, String id, Map<String, dynamic> body) =>
      _client.patch(ApiEndpoints.teamDetails(id), token: token, body: body);

  Future<List<Map<String, dynamic>>> list(String token) async {
    final result = await _client.get(ApiEndpoints.team,
        token: token, queryParameters: {'tab': 'teams'});
    final records = result['teams'] ?? result['data'];
    if (records is! List || records.any((item) => item is! Map)) {
      throw const ApiException('The server returned an invalid team list.');
    }
    return records
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> details(String token, String name) =>
      _client.get(ApiEndpoints.teamDetails(name), token: token);

  Future<Map<String, dynamic>> create(
          String token, Map<String, dynamic> payload) =>
      _client.post(ApiEndpoints.teams, token: token, body: payload);

  Future<void> delete(String token, String id) async {
    await _client.delete(ApiEndpoints.teamDetails(id), token: token);
  }
}
