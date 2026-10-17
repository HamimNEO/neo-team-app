import 'package:flutter/cupertino.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'datasources/activity_api.dart';

class ActivityStore extends FrameSafeNotifier {
  ActivityStore._({required ActivityApi api}) : _api = api;

  static final ActivityStore instance = _create();

  static ActivityStore _create() {
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => AuthSession.instance.accessToken,
      onUnauthorized: (token) => AuthSession.instance.invalidate(token),
    );
    return ActivityStore._(api: ActivityApi(client));
  }

  final ActivityApi _api;

  bool _isLoading = false;
  String? _error;
  String _filter = 'all';

  List<Map<String, dynamic>> _todayActivities = [];
  List<Map<String, dynamic>> _yesterdayActivities = [];
  List<Map<String, dynamic>> _earlierActivities = [];

  bool get isLoading => _isLoading;

  String? get error => _error;

  String get filter => _filter;

  List<Map<String, dynamic>> get todayActivities =>
      List.unmodifiable(_todayActivities);

  List<Map<String, dynamic>> get yesterdayActivities =>
      List.unmodifiable(_yesterdayActivities);

  List<Map<String, dynamic>> get earlierActivities =>
      List.unmodifiable(_earlierActivities);

  int get totalActivitiesCount =>
      _todayActivities.length +
      _yesterdayActivities.length +
      _earlierActivities.length;

  Future<void> load({String? filter}) async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !AuthSession.instance.signedIn) return;

    if (filter != null) {
      _filter = filter;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.list(token, filter: _filter);
      final groups = res['groups'];
      if (groups is Map) {
        _todayActivities = _parseList(groups['today']);
        _yesterdayActivities = _parseList(groups['yesterday']);
        _earlierActivities = _parseList(groups['earlier']);
      } else if (res['data'] is List) {
        _todayActivities = _parseList(res['data']);
        _yesterdayActivities = [];
        _earlierActivities = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic rawList) {
    if (rawList is! List) return [];
    return rawList
        .map<Map<String, dynamic>>((item) {
          if (item is! Map) return {};
          final map = Map<String, dynamic>.from(item);
          final kind = map['kind']?.toString().toLowerCase() ?? '';
          final description = map['description']?.toString() ?? '';
          final occurredAt = map['occurred_at']?.toString() ?? '';
          final actor = map['actor'] is Map ? map['actor'] as Map : {};
          final isMine = actor['is_current_user'] == true;
          final userName =
              isMine ? 'You' : (actor['name']?.toString() ?? 'User');

          return {
            'user': userName,
            'action': description.isNotEmpty
                ? description
                : (map['event']?.toString() ?? 'activity'),
            'entity': '',
            'time': _formatTime(occurredAt),
            'icon': _mapIcon(kind),
            'color': _mapColor(kind),
            'category': _mapCategory(kind),
            'isMine': isMine,
            'raw': map,
          };
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return 'Today';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  String _mapCategory(String kind) {
    switch (kind) {
      case 'leads':
        return 'Leads';
      case 'followups':
        return 'Follow-ups';
      case 'visits':
        return 'Visits';
      case 'tasks':
        return 'Tasks';
      case 'issues':
        return 'Issues';
      case 'team_admin':
        return 'Team';
      default:
        return 'Other';
    }
  }

  IconData _mapIcon(String kind) {
    switch (kind) {
      case 'leads':
        return CupertinoIcons.person_2;
      case 'followups':
        return CupertinoIcons.arrow_turn_down_left;
      case 'visits':
        return CupertinoIcons.house_fill;
      case 'tasks':
        return CupertinoIcons.checkmark_rectangle;
      case 'issues':
        return CupertinoIcons.exclamationmark_octagon;
      default:
        return CupertinoIcons.bolt_fill;
    }
  }

  Color _mapColor(String kind) {
    switch (kind) {
      case 'leads':
        return AppColors.brandLight;
      case 'followups':
        return AppColors.warning;
      case 'visits':
        return AppColors.leadVisit;
      case 'tasks':
        return AppColors.leadContacted;
      case 'issues':
        return AppColors.error;
      default:
        return AppColors.brandLight;
    }
  }
}
