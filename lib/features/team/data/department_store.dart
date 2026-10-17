import 'package:flutter/foundation.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/department.dart';
import 'datasources/department_api.dart';
import 'datasources/department_cache.dart';
import 'repositories/department_repository.dart';

class DepartmentStore extends FrameSafeNotifier {
  DepartmentStore(
      {required AuthSession session, required DepartmentRepository repository})
      : _session = session,
        _repository = repository {
    _token = session.accessToken;
    session.addListener(_sessionChanged);
  }

  static final instance = _create();

  static DepartmentStore _create() {
    final session = AuthSession.instance;
    return DepartmentStore(
        session: session,
        repository: DepartmentRepository(
          api: DepartmentApi(ApiClient(
              baseUrl: () => AppConfig.apiBaseUrl,
              accessToken: () => session.accessToken,
              onUnauthorized: session.invalidate)),
          cache: const DepartmentCache(PreferencesStore()),
        ));
  }

  final AuthSession _session;
  final DepartmentRepository _repository;
  List<DepartmentItem> _items = [];
  String? _token;
  int _revision = 0;
  int _accountVersion = 0;

  int get accountVersion => _accountVersion;
  Future<void>? _loadFuture;
  Future<void> _cacheWrites = Future.value();
  bool loading = false, saving = false, hasData = false;
  String? error, cacheError;

  bool get canManage => _session.isAdmin;

  List<DepartmentItem> get departments => List.unmodifiable(_items);

  DepartmentItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _sessionChanged() {
    if (_token == _session.accessToken) return;
    _token = _session.accessToken;
    _revision++;
    _accountVersion++;
    _items = [];
    _loadFuture = null;
    loading = saving = hasData = false;
    error = cacheError = null;
    notifyListeners();
  }

  Future<void> load() {
    if (_token == null || saving) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final token = _token!;
    final account = _session.user!.id;
    final revision = _revision;
    bool current() => token == _token && revision == _revision;
    loading = true;
    error = null;
    notifyListeners();
    if (!hasData) {
      try {
        final cached = await _repository.readCache(account, admin: canManage);
        if (!current()) return;
        if (cached != null) {
          _items = cached;
          hasData = true;
          notifyListeners();
        }
      } catch (_) {
        /* A cache problem must not stop the API request. */
      }
    }
    if (!current()) return;
    try {
      final items = await _repository.list(token, admin: canManage);
      if (!current()) return;
      _items = items;
      hasData = true;
      await _persist(account, token, revision);
    } catch (exception) {
      if (current()) error = messageFor(exception);
    } finally {
      if (current()) {
        loading = false;
        _loadFuture = null;
        notifyListeners();
      }
    }
  }

  Future<DepartmentItem> details(String id) async {
    final token = _token;
    final revision = _revision;
    if (token == null) throw const ApiException('Please sign in again.');
    final item = await _repository.details(token, id);
    if (_token != token || _revision != revision) {
      throw const ApiException('The department changed. Please refresh.');
    }
    return item;
  }

  Future<DepartmentItem> save(
      {DepartmentItem? department,
      required String name,
      required String code,
      required bool active}) async {
    if (name.trim().isEmpty || code.trim().isEmpty) {
      throw const ApiException('Enter a department name and code.');
    }
    DepartmentItem? result;
    await _mutate((token) async {
      result = department == null
          ? await _repository.create(token,
              name: name.trim(), code: code.trim(), active: active)
          : await _repository.update(token, department.id,
              name: name.trim(), code: code.trim(), active: active);
      return () {
        final index = _items.indexWhere((item) => item.id == result!.id);
        if (index < 0) {
          _items = [..._items, result!];
        } else {
          _items = [..._items]..[index] = result!;
        }
      };
    });
    return result!;
  }

  Future<void> delete(String id) => _mutate((token) async {
        await _repository.delete(token, id);
        return () {
          _items = _items.where((item) => item.id != id).toList();
        };
      });

  Future<void> assignMembers(String id, List<int> employeeIds) async {
    if (employeeIds.isEmpty || employeeIds.any((id) => id <= 0)) {
      throw const ApiException('Choose valid employees for this department.');
    }
    await _mutate((token) async {
      await _repository.assignMembers(token, id, employeeIds);
      return () {};
    });
    await load();
  }

  Future<void> removeMember(String id, String employeeId) async {
    await _mutate((token) async {
      await _repository.removeMember(token, id, employeeId);
      return () {};
    });
    await load();
  }

  Future<void> _mutate(Future<VoidCallback> Function(String) operation) async {
    if (!canManage || _token == null) {
      throw const ApiException(
          'Only a super administrator can manage departments.');
    }
    if (saving) {
      throw const ApiException('A department change is already in progress.');
    }
    final token = _token!;
    final account = _session.user!.id;
    final revision = ++_revision;
    _loadFuture = null;
    loading = false;
    saving = true;
    notifyListeners();
    try {
      final apply = await operation(token);
      if (token != _token || revision != _revision) {
        throw const ApiException(
            'Your session changed. Sign in again to view the saved department.');
      }
      apply();
      error = null;
      await _persist(account, token, revision);
    } finally {
      if (token == _token && revision == _revision) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> _persist(String account, String token, int revision) {
    final snapshot = List<DepartmentItem>.from(_items);
    final admin = canManage;
    _cacheWrites = _cacheWrites.then((_) async {
      if (token != _token || revision != _revision || !hasData) return;
      try {
        await _repository.saveCache(account, snapshot, admin: admin);
        if (token == _token && revision == _revision) cacheError = null;
      } catch (_) {
        // A confirmed server write is still successful when local storage fails.
        if (token == _token && revision == _revision) {
          cacheError =
              'Departments are up to date, but the offline cache could not be saved.';
        }
      }
    });
    return _cacheWrites;
  }

  static String messageFor(Object exception) => exception is FormatException
      ? exception.message
      : 'Unable to load departments. Please try again.';

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }
}
