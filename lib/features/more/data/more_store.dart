import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'datasources/more_api.dart';

class MoreStore extends FrameSafeNotifier {
  MoreStore._({required MoreApi api}) : _api = api {
    _token = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(_sessionChanged);
  }

  String? _token;

  void _sessionChanged() {
    final token = AuthSession.instance.accessToken;
    if (token == _token) return;
    _token = token;
    _followupsToday = _followupsOverdue = _followupsUpcoming = _visitsCount =
        _issuesCount = _teamMembersCount =
            _recentActivityCount = _unreadNotificationsCount = 0;
    _myAccessData = _employeeDashboardData = _overviewData = null;
    _workspaceTitle = 'Workspace';
    _workspaceSubtitle = '';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  static final MoreStore instance = _create();

  static MoreStore _create() {
    final client = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => AuthSession.instance.accessToken,
      onUnauthorized: (token) => AuthSession.instance.invalidate(token),
    );
    return MoreStore._(api: MoreApi(client));
  }

  final MoreApi _api;

  bool _isLoading = false;
  String? _error;

  int _followupsToday = 0;
  int _followupsOverdue = 0;
  int _followupsUpcoming = 0;
  int _visitsCount = 0;
  int _issuesCount = 0;
  int _teamMembersCount = 0;
  int _recentActivityCount = 0;
  int _unreadNotificationsCount = 0;
  String _workspaceTitle = 'Workspace';
  String _workspaceSubtitle = '';

  Map<String, dynamic>? _myAccessData;
  Map<String, dynamic>? _employeeDashboardData;
  Map<String, dynamic>? _overviewData;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get followupsToday => _followupsToday;

  int get followupsOverdue => _followupsOverdue;

  int get followupsUpcoming => _followupsUpcoming;

  int get visitsCount => _visitsCount;

  int get issuesCount => _issuesCount;

  int get teamMembersCount => _teamMembersCount;

  int get recentActivityCount => _recentActivityCount;

  int get unreadNotificationsCount => _unreadNotificationsCount;

  String get workspaceTitle => _workspaceTitle;

  String get workspaceSubtitle => _workspaceSubtitle;

  Map<String, dynamic>? get myAccessData => _myAccessData;

  Map<String, dynamic>? get employeeDashboardData => _employeeDashboardData;

  Map<String, dynamic>? get overviewData => _overviewData;

  Future<void> load() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || !AuthSession.instance.signedIn) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final summary = await _api.getSummary(token);
      if (token != AuthSession.instance.accessToken) return;
      final work = summary['work'];
      if (work is Map) {
        final followups = work['followups'];
        if (followups is Map) {
          _followupsToday = (followups['today'] as num?)?.toInt() ?? 0;
          _followupsOverdue = (followups['overdue'] as num?)?.toInt() ?? 0;
          _followupsUpcoming = (followups['upcoming'] as num?)?.toInt() ?? 0;
        }
        _visitsCount = (work['visits'] as num?)?.toInt() ?? 0;
        _issuesCount = (work['issues'] as num?)?.toInt() ?? 0;
        _teamMembersCount = (work['team_members'] as num?)?.toInt() ?? 0;
        _recentActivityCount =
            (work['recent_activity_count'] as num?)?.toInt() ?? 0;
      }

      final notifs = summary['notifications'];
      if (notifs is Map) {
        _unreadNotificationsCount =
            (notifs['unread_count'] as num?)?.toInt() ?? 0;
      }

      final ws = summary['workspace'];
      if (ws is Map) {
        _workspaceTitle = ws['title']?.toString() ?? _workspaceTitle;
        _workspaceSubtitle = ws['subtitle']?.toString() ?? _workspaceSubtitle;
      }
    } catch (e) {
      if (token != AuthSession.instance.accessToken) return;
      _error = e.toString();
    } finally {
      if (token == AuthSession.instance.accessToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>?> loadMyAccess() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return null;
    try {
      final data = await _api.getMyAccess(token);
      if (token != AuthSession.instance.accessToken) return null;
      _myAccessData = data;
      notifyListeners();
      return _myAccessData;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadEmployeeDashboard() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return null;
    try {
      final data = await _api.getEmployeeDashboard(token);
      if (token != AuthSession.instance.accessToken) return null;
      _employeeDashboardData = data;
      notifyListeners();
      return _employeeDashboardData;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadOverview() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return null;
    try {
      final data = await _api.getOverview(token);
      if (token != AuthSession.instance.accessToken) return null;
      _overviewData = data;
      notifyListeners();
      return _overviewData;
    } catch (_) {
      return null;
    }
  }
}
