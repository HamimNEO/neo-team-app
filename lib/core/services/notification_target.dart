/// Only app routes supported by the router can come from notification payloads.
class NotificationTarget {
  static String route(Map<String, dynamic> data) {
    final screen = _screen(data['screen']?.toString());
    if (screen != null) return screen;
    final entity = data['entity'];
    final type = (data['work_item_type'] ??
                data['target_type'] ??
                data['type'] ??
                data['entity_type'] ??
                (entity is Map ? entity['type'] : null))
            ?.toString()
            .toLowerCase() ??
        '';
    final rawId = data['target_id'] ??
        data['entity_id'] ??
        data['lead_id'] ??
        data['work_item_id'] ??
        (entity is Map ? entity['id'] : null);
    final id = rawId?.toString();
    final safeId = id != null && RegExp(r'^\d+$').hasMatch(id) ? id : null;
    if (safeId != null) {
      final kind = type.replaceAll('-', '_');
      final normalized =
          kind.startsWith('follow_up') || kind.startsWith('followup')
              ? 'followup'
              : kind.split('_').first;
      switch (normalized) {
        case 'employee':
        case 'probation':
          return '/employee/$safeId';
        case 'lead':
          return '/leads/$safeId';
        case 'task':
          return '/tasks/$safeId';
        case 'issue':
          return '/issues/$safeId';
        case 'visit':
          return '/visit-details/$safeId';
        case 'followup':
        case 'follow-up':
          return '/follow-up-details/$safeId';
        case 'expense':
          return '/expense-details/$safeId';
        case 'message':
        case 'conversation':
        case 'chat':
          final isGroup = data['group_id'] != null ||
              data['type'] == 'group' ||
              data['type'] == 'team' ||
              data['type'] == 'department';
          if (isGroup) {
            return '/message-groups/$safeId';
          }
          final senderId = data['sender_employee_id'] ??
              data['employee_id'] ??
              data['sender_id'];
          if (senderId != null) {
            final sStr = senderId.toString();
            final empId = sStr.startsWith('api_emp_') || sStr.startsWith('emp_')
                ? sStr
                : 'api_emp_$sStr';
            return '/messages/$empId';
          }
          return '/messages';
      }
    }
    if (type.contains('attendance') || type.contains('leave')) {
      return '/attendance';
    }
    if (type.contains('meal') || type.contains('lunch')) {
      return '/meals';
    }
    if (type.contains('message') || type.contains('chat')) {
      return '/messages';
    }
    if (type.contains('expense')) {
      return '/expenses';
    }
    final link = Uri.tryParse(data['deep_link']?.toString() ?? '');
    if (link?.scheme == 'neonecy-team') {
      final parts = [link!.host, ...link.pathSegments];
      if (parts.length == 2 && RegExp(r'^\d+$').hasMatch(parts[1])) {
        switch (parts[0]) {
          case 'leads':
            return '/leads/${parts[1]}';
          case 'tasks':
          case 'work-items':
            return '/tasks/${parts[1]}';
          case 'visits':
            return '/visit-details/${parts[1]}';
          case 'follow-ups':
            return '/follow-up-details/${parts[1]}';
          case 'issues':
            return '/issues/${parts[1]}';
          case 'expenses':
            return '/expense-details/${parts[1]}';
          case 'messages':
            return '/messages/${parts[1]}';
          case 'message-groups':
            return '/message-groups/${parts[1]}';
        }
      }
    }
    return '/notifications';
  }

  static String? _screen(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final parts = uri.pathSegments;
    if (parts.length != 2) return null;
    final id = parts[1];
    if (parts[0] == 'employee') {
      return '/employee/$id';
    }
    if (!RegExp(r'^\d+$').hasMatch(id)) return null;
    return switch (parts[0]) {
      'leads' => '/leads/$id',
      'tasks' || 'work-items' => '/tasks/$id',
      'issues' => '/issues/$id',
      'visits' || 'visit-details' => '/visit-details/$id',
      'follow-ups' || 'follow-up-details' => '/follow-up-details/$id',
      'expenses' || 'expense-details' => '/expense-details/$id',
      'messages' => '/messages/$id',
      'message-groups' => '/message-groups/$id',
      _ => null,
    };
  }
}
