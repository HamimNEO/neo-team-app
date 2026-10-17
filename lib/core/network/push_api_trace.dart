import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../diagnostics/push_debug.dart';

/// Traces mutations that can notify staff, without dumping private payloads.
class PushApiTrace {
  PushApiTrace._(this.request, Map? body)
      : id = '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
        _clock = Stopwatch()..start() {
    PushDebug.log('api.request', {
      'trace_id': id,
      'method': request.method,
      'host': request.url.host,
      'path': request.url.path,
      'payload_fields': body?.keys.map((key) => '$key').toList() ?? [],
      ...PushDebug.metadata(body ?? {}),
      if (body?['fcm_token'] is String)
        'fcm_fingerprint': PushDebug.fingerprint(body!['fcm_token'] as String),
    });
  }

  static int _sequence = 0;
  final http.BaseRequest request;
  final String id;
  final Stopwatch _clock;

  static PushApiTrace? start(http.BaseRequest request, Map? body) {
    if (!kDebugMode || request.method == 'GET') return null;
    if (!RegExp(
            r'/(?:super-admin/)?team-operations/(?:leads|work-items|tasks|follow-ups|visits|issues|push-devices|push-notification-preferences)(?:/|$)')
        .hasMatch(request.url.path)) {
      return null;
    }
    return PushApiTrace._(request, body);
  }

  void received(http.Response response) {
    PushDebug.log('api.http_response', {
      'trace_id': id,
      'http_status': response.statusCode,
      'elapsed_ms': _clock.elapsedMilliseconds,
      if (response.headers['x-request-id'] != null)
        'server_request_id': response.headers['x-request-id'],
      if (response.headers['cf-ray'] != null)
        'cf_ray': response.headers['cf-ray'],
    });
  }

  void success(Map<String, dynamic> data) {
    final dispatch = _dispatch(data);
    final record =
        data['lead'] ?? data['work_item'] ?? data['device'] ?? data['data'];
    PushDebug.log('api.accepted', {
      'trace_id': id,
      'response_keys': data.keys.toList(),
      'record': PushDebug.metadata(record is Map ? record : data),
      'dispatch_metadata': dispatch,
      'delivery_confirmation': 'requires_device_receipt',
      'note': dispatch.isEmpty
          ? 'API accepted the action; response contains no push dispatch diagnostics.'
          : 'Backend dispatch metadata returned; device receipt must be checked separately.',
    });
  }

  static Map<String, Object?> _dispatch(Map data, [int depth = 0]) => {
        for (final key in const [
          'push_sent',
          'push_status',
          'push_count',
          'notifications_sent',
          'success_count',
          'failure_count',
          'queued',
          'job_id',
          'error_code',
          'fcm_error_code',
          'push_error_code',
        ])
          if (data[key] is num ||
              data[key] is bool ||
              (data[key] is String &&
                  RegExp(r'^[\w./:-]{1,100}$').hasMatch(data[key])))
            key: data[key],
        if (depth < 2)
          for (final key in const [
            'data',
            'push',
            'push_dispatch',
            'dispatch',
            'fcm'
          ])
            if (data[key] is Map && _dispatch(data[key], depth + 1).isNotEmpty)
              key: _dispatch(data[key], depth + 1),
      };

  void failed(Object error) => PushDebug.log('api.failed', {
        'trace_id': id,
        'error_type': error.runtimeType.toString(),
        'elapsed_ms': _clock.elapsedMilliseconds,
      });
}
