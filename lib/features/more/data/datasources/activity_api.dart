import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ActivityApi {
  const ActivityApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> list(
    String token, {
    String filter = 'all',
    int perPage = 30,
    int page = 1,
  }) async {
    final response = await _client.get(
      ApiEndpoints.activityFeed,
      queryParameters: {
        'filter': filter,
        'per_page': perPage.toString(),
        'page': page.toString(),
      },
      token: token,
    );
    return response;
  }
}
