import 'dart:convert';
import 'dart:io';

class EmailService {
  EmailService._();

  static final EmailService instance = EmailService._();

  static const String serviceId = 'service_22pg0de';
  static const String templateId = 'template_x1vivzb';
  static const String publicKey = 'jnbpVMMxod5JhAL7B';
  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<bool> sendEmail({
    required String name,
    required String email,
    required String requestType,
    required String message,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final uri = Uri.parse(_endpoint);
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('Origin', 'https://neonecy.com');
      request.headers.set('User-Agent', 'NEC-TEAM-App/1.0.2');

      final payload = jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'name': name.trim().isNotEmpty ? name.trim() : 'Team Member',
          'email': email.trim(),
          'request_type': requestType,
          'message': message.trim(),
          'time': DateTime.now().toLocal().toString().split('.').first,
        },
      });

      request.write(payload);
      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException('Server returned ${response.statusCode}: $body');
      }
    } finally {
      client?.close();
    }
  }
}
