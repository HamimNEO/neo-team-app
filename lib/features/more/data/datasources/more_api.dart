import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class MoreApi {
  const MoreApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getSummary(String token) async {
    final response = await _client.get(
      ApiEndpoints.moreSummary,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getMyAccess(String token) async {
    final response = await _client.get(
      ApiEndpoints.myAccess,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getOverview(String token) async {
    final response = await _client.get(
      ApiEndpoints.staffOverview,
      token: token,
    );
    return response;
  }

  Future<Map<String, dynamic>> getEmployeeDashboard(String token) async {
    final response = await _client.get(
      ApiEndpoints.employeeDashboard,
      token: token,
    );
    return response;
  }
}
