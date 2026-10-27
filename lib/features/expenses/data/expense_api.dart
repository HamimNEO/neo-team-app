import '../../../core/network/api_client.dart';

class ExpenseApi {
  const ExpenseApi(this.client);

  final ApiClient client;
  static const path = '/team-operations/expenses';

  Future<List<Map<String, dynamic>>> list(String token,
          {Map<String, String>? filters}) =>
      client.all(path, token: token, queryParameters: filters);

  Future<Map<String, dynamic>> summary(String token, String month) => client
      .get('$path/summary', token: token, queryParameters: {'month': month});

  Future<Map<String, dynamic>> detail(String token, String id) =>
      client.get('$path/${Uri.encodeComponent(id)}', token: token);

  Future<Map<String, dynamic>> save(String token, Map<String, dynamic> body,
      {String? id, ApiUpload? receipt}) {
    final target = id == null ? path : '$path/${Uri.encodeComponent(id)}';
    if (receipt != null) {
      return client.multipart(target, token: token, fields: {
        if (id != null) '_method': 'PATCH',
        for (final entry in body.entries) entry.key: entry.value.toString()
      }, files: [
        receipt
      ]);
    }
    return id == null
        ? client.post(target, body: body, token: token)
        : client.patch(target, body: body, token: token);
  }

  Future<void> delete(String token, String id) async {
    await client.delete('$path/${Uri.encodeComponent(id)}', token: token);
  }
}
