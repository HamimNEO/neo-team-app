import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Push diagnostics deliberately omit auth headers and notification contents.
class PushDebug {
  PushDebug._();

  static void log(String event, [Map<String, Object?> fields = const {}]) {
    // Deliberately empty to eliminate verbose console noise in normal runs.
  }

  static String? fingerprint(String? token) => token == null
      ? null
      : sha256.convert(utf8.encode(token)).toString().substring(0, 12);

  static Map<String, Object?> metadata(Map data) => {
        for (final key in const [
          'id',
          'type',
          'status',
          'notification_id',
          'target_id',
          'target_type',
          'entity_id',
          'entity_type',
          'lead_id',
          'work_item_id',
          'work_item_type',
          'screen',
          'recipient_user_id',
          'recipient_employee_id',
          'user_id',
          'employee_id',
          'assigned_employee_id',
          'assignee_employee_id',
          'assigned_to_employee_id',
          'current_owner_id',
          'device_id',
          'platform',
          'app_version',
        ])
          if (data.containsKey(key)) key: _scalar(data[key]),
      };

  static Object? _scalar(Object? value) => value is String
      ? (value.length > 160 ? '${value.substring(0, 160)}…' : value)
      : value is num || value is bool || value == null
          ? value
          : '<${value.runtimeType}>';
}
