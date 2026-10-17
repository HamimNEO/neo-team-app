import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/core/network/api_exception.dart';

void main() {
  test('authenticated 401 invalidates exactly the token used for the request',
      () async {
    String? rejected;
    final client = ApiClient(
      baseUrl: () => 'https://example.test/api',
      client: MockClient((_) async => http.Response('{}', 401)),
      accessToken: () => 'current-token',
      onUnauthorized: (token) async => rejected = token,
    );
    addTearDown(client.close);
    await expectLater(
        client.get('/team-operations/me'), throwsA(isA<ApiException>()));
    expect(rejected, 'current-token');
  });

  test('login rejection never invalidates an existing authenticated session',
      () async {
    var invalidated = false;
    final client = ApiClient(
      baseUrl: () => 'https://example.test/api',
      client: MockClient((_) async => http.Response('{}', 401)),
      accessToken: () => 'current-token',
      onUnauthorized: (_) async => invalidated = true,
    );
    addTearDown(client.close);
    await expectLater(client.post('/login', body: {}, authenticated: false),
        throwsA(isA<ApiException>()));
    expect(invalidated, isFalse);
  });

  test('HTML gateway errors do not expose raw response bodies', () async {
    final client = ApiClient(
      baseUrl: () => 'https://example.test/api',
      client: MockClient(
          (_) async => http.Response('<html>private server trace</html>', 502)),
    );
    addTearDown(client.close);
    await expectLater(
        client.post('/login', body: {}, authenticated: false),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            'The server is unavailable. Please try again later.')));
  });

  test('invalid successful responses cannot be treated as authenticated data',
      () async {
    final client = ApiClient(
      baseUrl: () => 'https://example.test/api',
      client: MockClient((_) async => http.Response('not JSON', 200)),
    );
    addTearDown(client.close);
    await expectLater(client.post('/login', body: {}, authenticated: false),
        throwsA(isA<ApiException>()));
  });

  test('transport timeout gives a usable error', () async {
    final pending = Completer<http.Response>();
    final client = ApiClient(
      baseUrl: () => 'https://example.test/api',
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) => pending.future),
    );
    addTearDown(client.close);
    await expectLater(
        client.post('/login', body: {}, authenticated: false),
        throwsA(isA<ApiException>().having((e) => e.message, 'message',
            'The request timed out. Please try again.')));
    pending.complete(http.Response('{}', 200));
  });

  test('invalid base URL fails before transmitting credentials', () async {
    final client = ApiClient(
      baseUrl: () => 'http://example.test/api',
      client: MockClient((_) async => fail('Credentials must use HTTPS')),
    );
    addTearDown(client.close);
    await expectLater(client.post('/login', body: {}, authenticated: false),
        throwsA(isA<ApiException>()));
  });
}
