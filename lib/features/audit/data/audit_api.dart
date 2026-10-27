import '../../../core/network/api_client.dart';

class AuditApi {
  const AuditApi(this.client);

  final ApiClient client;
  static const path = '/team-operations/administration/audit-logs';

  Future<List<Map<String, dynamic>>> list(String token,
          {Map<String, String>? filters}) =>
      client.all(path, token: token, queryParameters: filters);

  Future<Map<String, dynamic>> detail(String token, String id) =>
      client.get('$path/${Uri.encodeComponent(id)}', token: token);
}
