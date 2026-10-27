import '../../../core/network/api_client.dart';

class CertificateApi {
  const CertificateApi(this.client);

  final ApiClient client;
  static const path = '/team-operations/certificates';

  Future<List<Map<String, dynamic>>> list(String token, bool admin) =>
      client.all(admin ? path : '$path/my', token: token);

  Future<Map<String, dynamic>> submit(
          String token, Map<String, dynamic> body) =>
      client.post('$path/requests', token: token, body: body);

  Future<Map<String, dynamic>> action(String token, String id, String action,
          {Map<String, dynamic>? body}) =>
      client.post('$path/${Uri.encodeComponent(id)}/$action',
          token: token, body: body);

  Future<Map<String, dynamic>> deliver(String token, String id,
          Map<String, String> fields, List<ApiUpload> files) =>
      client.multipart('$path/${Uri.encodeComponent(id)}/deliver',
          token: token, fields: fields, files: files);
}
