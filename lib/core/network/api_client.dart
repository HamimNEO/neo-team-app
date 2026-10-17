import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'push_api_trace.dart';

class ApiUpload {
  const ApiUpload(
      {required this.field,
      required this.bytes,
      required this.filename,
      this.mimeType = 'image/png'});

  final String field, filename, mimeType;
  final Uint8List bytes;
}

/// Shared JSON and binary transport. Features own endpoint/payload details.
class ApiClient {
  ApiClient({
    required String Function() baseUrl,
    http.Client? client,
    String? Function()? accessToken,
    Future<void> Function(String rejectedToken)? onUnauthorized,
    this.timeout = const Duration(seconds: 25),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _accessToken = accessToken,
        _onUnauthorized = onUnauthorized;

  final String Function() _baseUrl;
  final http.Client _client;
  final String? Function()? _accessToken;
  final Future<void> Function(String rejectedToken)? _onUnauthorized;
  final Duration timeout;

  Future<Map<String, dynamic>> get(String path,
          {Map<String, String>? queryParameters,
          String? token,
          bool authenticated = true}) =>
      _request('GET', path,
          queryParameters: queryParameters,
          token: token,
          authenticated: authenticated);

  Future<Map<String, dynamic>> post(String path,
          {Map<String, dynamic>? body,
          String? token,
          bool authenticated = true}) =>
      _request('POST', path,
          body: body, token: token, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? body, String? token}) =>
      _request('PATCH', path, body: body, token: token, authenticated: true);

  Future<Map<String, dynamic>> put(String path,
          {Map<String, dynamic>? body, String? token}) =>
      _request('PUT', path, body: body, token: token, authenticated: true);

  Future<Map<String, dynamic>> multipart(String path,
      {required Map<String, String> fields,
      required List<ApiUpload> files,
      String? token}) {
    final bearer = _bearer(token, true);
    final request = http.MultipartRequest('POST', _uri(path, null))
      ..followRedirects = false
      ..headers.addAll(_headers(bearer)..remove('Content-Type'))
      ..fields.addAll(fields);
    for (final file in files) {
      request.files.add(http.MultipartFile.fromBytes(file.field, file.bytes,
          filename: file.filename,
          contentType: MediaType.parse(file.mimeType)));
    }
    return _send(request, bearer, true, debugBody: fields);
  }

  /// Downloads protected attachments without exposing the bearer to a browser.
  Future<Uint8List> download(String path, {String? token}) async {
    final bearer = _bearer(token, true);
    final headers = _headers(bearer)..remove('Content-Type');
    headers['Accept'] = '*/*';
    final request = http.Request('GET', _uri(path, null))
      ..followRedirects = false
      ..headers.addAll(headers);
    final response = await _perform(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _decodeResponse(response, bearer, true);
    }
    if (response.bodyBytes.isEmpty) {
      throw const ApiException('This attachment is empty.');
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> delete(String path,
          {Map<String, dynamic>? body, String? token}) =>
      _request('DELETE', path, body: body, token: token, authenticated: true);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body,
      Map<String, String>? queryParameters,
      String? token,
      required bool authenticated}) async {
    final bearer = _bearer(token, authenticated);
    final request = http.Request(method, _uri(path, queryParameters))
      ..followRedirects = false
      ..headers.addAll(_headers(bearer));
    if (body != null) request.body = jsonEncode(body);
    return _send(request, bearer, authenticated, debugBody: body);
  }

  Uri _uri(String path, Map<String, String>? queryParameters) {
    final base = Uri.tryParse(_baseUrl());
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.userInfo.isNotEmpty) {
      throw const ApiException('The API URL is missing or invalid.');
    }
    return base.replace(
        path:
            '${base.path.replaceFirst(RegExp(r'/+$'), '')}/${path.replaceFirst(RegExp(r'^/+'), '')}',
        queryParameters: queryParameters);
  }

  String? _bearer(String? token, bool authenticated) {
    final bearer = authenticated ? (token ?? _accessToken?.call()) : null;
    if (authenticated && (bearer == null || bearer.isEmpty)) {
      throw const ApiException('Please sign in again.', statusCode: 401);
    }
    return bearer;
  }

  Map<String, String> _headers(String? bearer) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent': 'NEC-Team-App/1.0',
        if (bearer != null) 'Authorization': 'Bearer $bearer',
      };

  Future<http.Response> _perform(http.BaseRequest request) async {
    final http.Response response;
    try {
      response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })()
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const ApiException(
          'Unable to connect to the server. Check your connection and try again.');
    }

    return response;
  }

  Future<Map<String, dynamic>> _send(
      http.BaseRequest request, String? bearer, bool authenticated,
      {Map? debugBody}) async {
    final trace = PushApiTrace.start(request, debugBody);
    try {
      final response = await _perform(request);
      trace?.received(response);
      final data = await _decodeResponse(response, bearer, authenticated);
      trace?.success(data);
      return data;
    } catch (error) {
      trace?.failed(error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _decodeResponse(
      http.Response response, String? bearer, bool authenticated) async {
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Non-JSON errors (e.g. proxy HTML) are presented safely below.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && authenticated && bearer != null) {
        await _onUnauthorized?.call(bearer);
      }
      throw ApiException(_errorMessage(response.statusCode, data),
          statusCode: response.statusCode);
    }
    if (response.statusCode == 204) return {};
    if (data == null) {
      throw const ApiException('The server returned an invalid response.');
    }
    return data;
  }

  String _errorMessage(int status, Map<String, dynamic>? data) {
    if (status == 401) return 'Your session has expired. Please sign in again.';
    if (status == 429) return 'Too many attempts. Please try again later.';
    if (status >= 500) {
      return 'The server is unavailable. Please try again later.';
    }
    if (data?['cloudflare_error'] == true) {
      return 'The API gateway denied this request. Please contact your administrator.';
    }
    final errors = data?['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
        if (value is String && value.isNotEmpty) return value;
      }
    }
    final message = data?['message'];
    if (message is String && message.isNotEmpty) return message;
    if (status == 403) return 'This account does not have access.';
    return 'The request failed. Please try again.';
  }

  void close() => _client.close();
}
