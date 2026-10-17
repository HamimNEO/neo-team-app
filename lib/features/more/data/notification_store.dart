import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../../messages/data/message_store.dart';
import '../../team/data/employee_store.dart';
import 'datasources/notification_api.dart';

class NotificationStore extends FrameSafeNotifier {
  NotificationStore._({required NotificationApi api}) : _api = api {
    _token = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(_sessionChanged);
  }

  @visibleForTesting
  static NotificationStore createForTesting({required NotificationApi api}) =>
      NotificationStore._(api: api);

  String? _token;
  int _requestVersion = 0;
  bool hasLoaded = false;
  Future<void>? _loadFuture;

  void _sessionChanged() {
    final token = AuthSession.instance.accessToken;
    if (token == _token) return;
    _token = token;
    _requestVersion++;
    _loadFuture = null;
    hasLoaded = false;
    _isLoading = false;
    _error = null;
    _unreadCount = 0;
    _filter = 'all';
    _newNotifications = [];
    _todayNotifications = [];
    _yesterdayNotifications = [];
    _earlierNotifications = [];
    notifyListeners();
    if (token != null) Future.microtask(() => load());
  }

  static final NotificationStore instance = _create();

  static NotificationStore _create() {
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => AuthSession.instance.accessToken,
      onUnauthorized: (token) => AuthSession.instance.invalidate(token),
    );
    return NotificationStore._(api: NotificationApi(client));
  }

  final NotificationApi _api;

  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  String _filter = 'all';

  List<Map<String, dynamic>> _newNotifications = [];
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _yesterdayNotifications = [];
  List<Map<String, dynamic>> _earlierNotifications = [];

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get unreadCount => _unreadCount;

  String get filter => _filter;

  List<Map<String, dynamic>> get newNotifications =>
      List.unmodifiable(_newNotifications);

  List<Map<String, dynamic>> get todayNotifications =>
      List.unmodifiable(_todayNotifications);

  List<Map<String, dynamic>> get yesterdayNotifications =>
      List.unmodifiable(_yesterdayNotifications);

  List<Map<String, dynamic>> get earlierNotifications =>
      List.unmodifiable(_earlierNotifications);

  int get totalNotificationsCount =>
      _newNotifications.length +
      _todayNotifications.length +
      _yesterdayNotifications.length +
      _earlierNotifications.length;

  Future<void> load({String? filter, bool force = false}) {
    if (_token == null) return Future.value();
    final requestedFilter = filter ?? _filter;
    if (!force && requestedFilter == _filter && _loadFuture != null) {
      return _loadFuture!;
    }
    _filter = requestedFilter;
    final version = ++_requestVersion;
    return _loadFuture = _load(_token!, requestedFilter, version);
  }

  Future<void> _load(String token, String filter, int version) async {
    bool current() => token == _token && version == _requestVersion;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final all = <Map<String, dynamic>>[];
      int page = 1, lastPage = 1, unread = 0;
      do {
        final response =
            await _api.list(token, filter: filter, perPage: 100, page: page);
        if (!current()) return;
        if (response['data'] is! List) {
          throw const ApiException(
              'The server returned an invalid notification list.');
        }
        final currentPage = response['current_page'],
            last = response['last_page'];
        if (currentPage != page || last is! int || last < page) {
          throw const ApiException(
              'The server returned invalid notification pagination.');
        }
        lastPage = last;
        unread = int.tryParse('${response['unread_count']}') ?? 0;
        all.addAll((response['data'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m)));
        page++;
      } while (page <= lastPage);
      if (!current()) return;
      final unique = <String, Map<String, dynamic>>{};
      final contentSeen = <String>{};
      for (final row in all) {
        final id = row['id']?.toString();
        final body = '${row['body'] ?? ''}'.trim().toLowerCase();
        if (body.startsWith('[group avatar') || body.startsWith('[avatar:')) {
          continue;
        }
        final created = '${row['created_at'] ?? ''}';
        final signature =
            '${row['title']}|$body|${row['entity']}|${created.length >= 16 ? created.substring(0, 16) : created}';
        if (!contentSeen.add(signature)) continue;
        if (id != null && id.isNotEmpty) unique[id] = row;
      }
      List<Map<String, dynamic>> group(String key) =>
          _parseList(unique.values.where((m) => _dateGroup(m) == key).toList());
      _newNotifications = group('new');
      _todayNotifications = group('today');
      _yesterdayNotifications = group('yesterday');
      _earlierNotifications = group('earlier');
      _unreadCount = unread;
      hasLoaded = true;
    } catch (e) {
      if (current()) {
        _error = e is ApiException
            ? e.message
            : 'Unable to load notifications. Please retry.';
      }
    } finally {
      if (current()) {
        _isLoading = false;
        _loadFuture = null;
        notifyListeners();
      }
    }
  }

  String _dateGroup(Map<String, dynamic> row) {
    final group = row['date_group']?.toString();
    if (['new', 'today', 'yesterday', 'earlier'].contains(group)) return group!;
    if (row['is_read'] != true) return 'new';
    final date =
        DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
    if (date == null) return 'earlier';
    final now = DateTime.now(), day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'today';
    if (day == today.subtract(const Duration(days: 1))) return 'yesterday';
    return 'earlier';
  }

  List<Map<String, dynamic>> _parseList(dynamic rawList) {
    if (rawList is! List) return [];
    return rawList
        .map<Map<String, dynamic>>((item) {
          if (item is! Map) return {};
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString() ?? '';
          final title = map['title']?.toString() ?? '';
          var body = map['body']?.toString() ?? '';
          body = body
              .replaceAll(
                  RegExp(r'\s*\[\d{1,2}:\d{2}(\s*(?:AM|PM|am|pm))?\]',
                      caseSensitive: false),
                  '')
              .trim();
          if (body.toLowerCase() == '[attachment]') {
            body = 'Sent an attachment';
          } else {
            body = body
                .replaceAll(RegExp(r'\[attachment\]', caseSensitive: false),
                    'Sent an attachment')
                .trim();
          }
          if (body.isEmpty) {
            body = 'Sent an attachment';
          }
          final isRead = map['is_read'] == true;
          final type = (map['type'] ??
                      (map['entity'] is Map ? map['entity']['type'] : null))
                  ?.toString()
                  .toLowerCase() ??
              '';
          final createdAt = map['created_at']?.toString() ?? '';

          return {
            'id': id,
            'title': title,
            'subtitle': body,
            'time': _formatTimeAgo(createdAt),
            'category': _mapCategory(type, title),
            'icon': _mapIcon(type, title),
            'color': _mapColor(type, title),
            'isUnread': !isRead,
            'targetRoute': _mapRoute(type, map['entity'], map['data'], title),
            'raw': map,
          };
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return dateStr;
    }
  }

  String _mapCategory(String type, String title) {
    final t = '$type $title'.toLowerCase();
    if (t.contains('lead')) return 'Leads';
    if (t.contains('attendance') ||
        t.contains('leave') ||
        t.contains('meal') ||
        t.contains('lunch')) {
      return 'Attendance';
    }
    if (t.contains('message') ||
        t.contains('conversation') ||
        t.contains('chat')) {
      return 'Messages';
    }
    if (t.contains('task') ||
        t.contains('issue') ||
        t.contains('follow') ||
        t.contains('visit') ||
        t.contains('work')) {
      return 'Work';
    }
    return 'System';
  }

  IconData _mapIcon(String type, String title) {
    final t = '$type $title'.toLowerCase();
    if (t.contains('lead')) return CupertinoIcons.person_2;
    if (t.contains('message') ||
        t.contains('conversation') ||
        t.contains('chat')) {
      return CupertinoIcons.chat_bubble_fill;
    }
    if (t.contains('attendance')) return CupertinoIcons.clock_fill;
    if (t.contains('leave')) return CupertinoIcons.calendar;
    if (t.contains('meal') || t.contains('lunch')) return Icons.restaurant;
    if (t.contains('follow')) return CupertinoIcons.arrow_turn_down_left;
    if (t.contains('visit')) return CupertinoIcons.house_fill;
    if (t.contains('task')) return CupertinoIcons.checkmark_square;
    if (t.contains('issue')) return CupertinoIcons.exclamationmark_octagon;
    return CupertinoIcons.bell_fill;
  }

  Color _mapColor(String type, String title) {
    final t = '$type $title'.toLowerCase();
    if (t.contains('lead')) return AppColors.brandLight;
    if (t.contains('message') || t.contains('conversation')) {
      return const Color(0xFF1677FF);
    }
    if (t.contains('attendance')) return const Color(0xFF10B981);
    if (t.contains('meal') || t.contains('lunch')) {
      return const Color(0xFFF59E0B);
    }
    if (t.contains('follow')) return AppColors.warning;
    if (t.contains('visit')) return AppColors.leadVisit;
    if (t.contains('task')) return AppColors.leadContacted;
    if (t.contains('issue')) return AppColors.error;
    return AppColors.brandLight;
  }

  String _mapRoute(String type, dynamic entity, dynamic data, String title) {
    final entityMap = entity is Map ? entity : null;
    final dataMap = data is Map ? data : null;
    final entityType = entityMap?['type']?.toString().toLowerCase() ?? '';
    final combined = '$type $entityType $title'.toLowerCase();

    if (combined.contains('message') ||
        combined.contains('conversation') ||
        combined.contains('chat')) {
      final match =
          RegExp(r'from\s+([^:\(\n]+)', caseSensitive: false).firstMatch(title);
      final fromName = match?.group(1)?.trim();
      if (fromName != null && fromName.isNotEmpty) {
        final lower = fromName.toLowerCase();
        if (lower.contains('super admin') || lower == 'admin') {
          return '/messages/${AuthSession.adminEmployeeId}';
        }
        final emp = EmployeeStore.instance.employees.where((e) {
          final eName = e.name.toLowerCase();
          return eName == lower ||
              eName.contains(lower) ||
              lower.contains(eName);
        }).firstOrNull;
        if (emp != null) {
          return '/messages/${emp.id}';
        }
      }

      final groupId = dataMap?['group_id']?.toString();
      String? convId = dataMap?['conversation_id']?.toString();
      if (convId == null &&
          (entityType.contains('group') ||
              entityType.contains('conversation'))) {
        convId = entityMap?['id']?.toString();
      }

      final isGroup = (groupId != null && groupId.isNotEmpty) ||
          entityType.contains('group') ||
          entityType.contains('team') ||
          entityType.contains('department') ||
          dataMap?['type']?.toString().toLowerCase() == 'group' ||
          dataMap?['type']?.toString().toLowerCase() == 'team' ||
          dataMap?['type']?.toString().toLowerCase() == 'department' ||
          title.toLowerCase().contains('in ');

      if (isGroup) {
        final targetGroupId = (groupId != null && groupId.isNotEmpty)
            ? groupId
            : (convId != null && convId.isNotEmpty ? convId : null);
        if (targetGroupId != null) {
          return '/message-groups/$targetGroupId';
        }
        return '/messages';
      }

      final senderMap =
          dataMap?['sender'] is Map ? dataMap!['sender'] as Map : null;
      final rawSenderId = dataMap?['sender_employee_id'] ??
          dataMap?['employee_id'] ??
          dataMap?['sender_id'] ??
          senderMap?['employee_id'] ??
          senderMap?['id'];
      if (rawSenderId != null) {
        final idStr = rawSenderId.toString();
        final emp = EmployeeStore.instance.byId(idStr) ??
            EmployeeStore.instance.byId('api_emp_$idStr');
        if (emp != null) return '/messages/${emp.id}';
        return '/messages/${idStr.startsWith('api_emp_') ? idStr : 'api_emp_$idStr'}';
      }

      if (convId != null) {
        final contact = MessageStore.instance.contactForConversationId(convId);
        if (contact != null) return '/messages/$contact';
        if (convId == '1') {
          return '/messages/${AuthSession.instance.isAdmin ? 'api_emp_2' : AuthSession.adminEmployeeId}';
        }
      }

      return '/messages';
    }

    final explicitRoute =
        dataMap?['route']?.toString() ?? dataMap?['target_route']?.toString();
    if (explicitRoute != null && explicitRoute.startsWith('/')) {
      return explicitRoute;
    }

    final rawId = entityMap?['id'] ??
        dataMap?['target_id'] ??
        dataMap?['entity_id'] ??
        dataMap?['id'] ??
        dataMap?['work_item_id'];
    final entityId = rawId?.toString();

    if (combined.contains('attendance')) {
      return AuthSession.instance.isAdmin ? '/attendance/admin' : '/attendance';
    }
    if (combined.contains('leave')) {
      return '/attendance';
    }

    if (combined.contains('meal') || combined.contains('lunch')) {
      return AuthSession.instance.isAdmin ? '/meals/admin' : '/meals';
    }

    if (combined.contains('expense')) {
      return entityId != null ? '/expense-details/$entityId' : '/expenses';
    }

    if (combined.contains('lead')) {
      return entityId != null ? '/leads/$entityId' : '/leads';
    }

    if (combined.contains('follow')) {
      return entityId != null ? '/follow-up-details/$entityId' : '/follow-ups';
    }

    if (combined.contains('visit')) {
      return entityId != null ? '/visit-details/$entityId' : '/visits';
    }

    if (combined.contains('task')) {
      return entityId != null ? '/tasks/$entityId' : '/tasks';
    }

    if (combined.contains('issue')) {
      return entityId != null ? '/issues/$entityId' : '/issues';
    }

    return '/home';
  }

  /// Resolves the destination route for any notification item dynamically on tap.
  String resolveRoute(Map<String, dynamic> item) {
    final raw = item['raw'] is Map ? item['raw'] as Map : null;
    final title = item['title']?.toString() ?? '';
    final category = item['category']?.toString() ?? '';
    final rawData = raw?['data'] is Map ? raw!['data'] as Map : null;
    final rawEntity = raw?['entity'] is Map ? raw!['entity'] as Map : null;
    final type = (raw?['type'] ?? rawEntity?['type'] ?? category)
            ?.toString()
            .toLowerCase() ??
        '';

    return _mapRoute(type, rawEntity, rawData, title);
  }

  @visibleForTesting
  String mapRouteForTesting({
    required String type,
    dynamic entity,
    dynamic data,
    required String title,
  }) =>
      _mapRoute(type, entity, data, title);

  Future<void> markAsRead(String id) async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');

    bool found = false;
    List<Map<String, dynamic>> updateList(List<Map<String, dynamic>> list) {
      return list.map((item) {
        if (item['id']?.toString() == id && item['isUnread'] == true) {
          found = true;
          return {
            ...item,
            'isUnread': false,
            if (item['raw'] is Map)
              'raw': {...(item['raw'] as Map), 'is_read': true},
          };
        }
        return item;
      }).toList();
    }

    _newNotifications = updateList(_newNotifications);
    _todayNotifications = updateList(_todayNotifications);
    _yesterdayNotifications = updateList(_yesterdayNotifications);
    _earlierNotifications = updateList(_earlierNotifications);

    if (found && _unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    try {
      await _api.markAsRead(token, id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final token = _token;
    if (token == null) throw const ApiException('Please sign in again.');

    List<Map<String, dynamic>> updateList(List<Map<String, dynamic>> list) {
      return list.map((item) {
        return {
          ...item,
          'isUnread': false,
          if (item['raw'] is Map)
            'raw': {...(item['raw'] as Map), 'is_read': true},
        };
      }).toList();
    }

    _newNotifications = updateList(_newNotifications);
    _todayNotifications = updateList(_todayNotifications);
    _yesterdayNotifications = updateList(_yesterdayNotifications);
    _earlierNotifications = updateList(_earlierNotifications);
    _unreadCount = 0;
    notifyListeners();

    try {
      await _api.markAllAsRead(token);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) throw const ApiException('Please sign in again.');
    return await _api.getPreferences(token);
  }

  Future<void> updatePreferences({
    Map<String, dynamic>? categories,
    Map<String, dynamic>? events,
  }) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) throw const ApiException('Please sign in again.');
    await _api.updatePreferences(token, categories: categories, events: events);
  }

  Future<void> registerPushDevice({
    required String fcmToken,
    String? deviceId,
    String? platform,
    String? appVersion,
  }) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    await _api.registerPushDevice(
      token,
      fcmToken: fcmToken,
      deviceId: deviceId,
      platform: platform,
      appVersion: appVersion,
    );
  }

  Future<void> removePushDevice({required String fcmToken}) async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;
    await _api.removePushDevice(token, fcmToken: fcmToken);
  }
}
