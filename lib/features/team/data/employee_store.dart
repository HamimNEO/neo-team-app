import '../../../core/constants/app_constants.dart';
import '../../../core/notifiers/frame_safe_notifier.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/storage/preferences_store.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import '../domain/models/employee.dart';
import '../domain/models/employee_role.dart';
import '../domain/models/employee_submission.dart';
import 'auth_employee_mapper.dart';
import 'datasources/employee_api.dart';
import 'datasources/employee_cache.dart';
import 'repositories/employee_repository.dart';

/// Backend employee directory. Old local employees and saved passwords are not read.
class EmployeeStore extends FrameSafeNotifier {
  EmployeeStore(
      {required AuthSession session, required EmployeeRepository repository})
      : _session = session,
        _repository = repository {
    _token = session.accessToken;
    session.addListener(_sessionChanged);
  }

  static final instance = _create();

  static EmployeeStore _create() {
    final session = AuthSession.instance;
    return EmployeeStore(
        session: session,
        repository: EmployeeRepository(
          api: EmployeeApi(ApiClient(
              baseUrl: () => AppConfig.apiBaseUrl,
              accessToken: () => session.accessToken,
              onUnauthorized: session.invalidate)),
          cache: const EmployeeCache(PreferencesStore()),
          baseUrl: () => AppConfig.apiBaseUrl,
        ));
  }

  final AuthSession _session;
  final EmployeeRepository _repository;

  static String get currentEmployeeId => AuthSession.instance.employeeId;
  List<Employee> _employees = [];
  Employee? _currentProfile;
  List<EmployeeRole> roles = [EmployeeRole.operations];
  String? _token, loadError, cacheError, roleError;
  int _revision = 0;
  bool loading = false, saving = false, hasData = false;
  Future<void>? _loading, _rolesLoading;
  Future<void>? _cacheReadFuture;
  Future<void> _cacheWrites = Future.value();

  List<Employee> get employees {
    if (!_session.isAdmin) {
      final adminEmp = byId(AuthSession.adminEmployeeId);
      if (adminEmp != null && !_employees.any((e) => e.id == adminEmp.id)) {
        return List.unmodifiable([adminEmp, ..._employees]);
      }
    }
    return List.unmodifiable(_employees);
  }

  List<Employee> get staffEmployees => employees;

  bool get canManage => _session.isAdmin;

  bool isStaffEmployee(String id) => byId(id)?.backendId != null;

  bool hasLogin(String id) => byId(id)?.backendId != null;

  String loginEmailFor(String id) => byId(id)?.email ?? '';

  Employee get currentEmployee =>
      byId(_session.employeeId) ??
      (_session.user != null
          ? authEmployee(_session.user!, _session.employeeId)
          : null) ??
      const Employee(
        id: 'emp_current',
        name: 'User',
        designation: 'Staff',
        department: 'General',
        team: 'General',
        systemRole: 'Staff',
        status: 'Active',
        email: '',
        phone: '',
        avatarInitials: 'U',
        joinedDate: '2026-01-01',
      );

  Employee? byId(String id) {
    if (id == _session.employeeId && _currentProfile?.id == id) {
      return _currentProfile;
    }
    for (final employee in _employees) {
      if (employee.id == id) return employee;
    }
    final user = _session.user;
    if (user != null && id == _session.employeeId) {
      return authEmployee(user, id);
    }
    if (id == AuthSession.adminEmployeeId ||
        id == 'usr_1' ||
        id == 'admin' ||
        id == 'emp_admin' ||
        id == 'api_emp_1') {
      return const Employee(
        id: AuthSession.adminEmployeeId,
        name: 'Super Admin',
        designation: 'Administrator',
        department: 'Administration',
        team: 'Platform',
        systemRole: 'Administrator',
        status: 'Active',
        email: 'dragon@bingi.com.bd',
        phone: '',
        avatarInitials: 'SA',
        avatarAsset: AppConstants.superAdminAvatarAsset,
        joinedDate: '',
        totalMealCost: 0,
        employeeCode: 'SUPER-ADMIN',
      );
    }
    return null;
  }

  String get nextEmployeeCode {
    var largest = 0;
    for (final employee in _employees) {
      final match =
          RegExp(r'^NEC-EMP-(\d+)$').firstMatch(employee.employeeCode);
      final number = int.tryParse(match?.group(1) ?? '') ?? 0;
      if (number > largest) largest = number;
    }
    return 'NEC-EMP-${(largest + 1).toString().padLeft(3, '0')}';
  }

  void _sessionChanged() {
    if (_token == _session.accessToken) {
      notifyListeners();
      return;
    }
    _token = _session.accessToken;
    _revision++;
    _employees = [];
    _currentProfile = null;
    roles = [EmployeeRole.operations];
    _loading = _rolesLoading = null;
    _cacheReadFuture = null;
    loading = saving = hasData = false;
    loadError = cacheError = roleError = null;
    notifyListeners();
  }

  Future<void> restoreCache() => _token == null || hasData
      ? Future.value()
      : _cacheReadFuture ??= _restoreCache();

  Future<void> _restoreCache() async {
    final token = _token, revision = _revision;
    final account = _session.user!.id, admin = canManage;
    try {
      final cached = await _repository.readCache(account, admin);
      if (token != _token || revision != _revision || hasData) return;
      if (cached != null) {
        _employees = cached;
        hasData = true;
        notifyListeners();
        NotificationService.instance
            .checkAndNotifyProbationEnd(employees: _employees)
            .ignore();
      }
    } catch (_) {
      /* A cache failure must not prevent a live fetch. */
    }
  }

  Future<void> load({bool preferCache = false}) async {
    if (_token == null || saving) return;
    final token = _token;
    if (preferCache) {
      await restoreCache();
      if (token != _token || hasData) return;
    }
    await (_loading ??= _load());
  }

  Future<void> _load() async {
    final token = _token!, account = _session.user!.id;
    final revision = _revision, admin = canManage;
    bool current() => token == _token && revision == _revision;
    loading = true;
    loadError = null;
    notifyListeners();
    await restoreCache();
    if (!current()) return;
    try {
      final fresh = await _repository.list(token, admin);
      if (!current()) return;
      _employees = fresh.map((item) {
        final old = byId(item.id);
        final isProbation = (old?.isProbation ?? false) ||
            item.employmentType == 'probation';
        return Employee.fromJson({
          ...item.toJson(),
          'photoBase64': old?.photoBase64 ?? item.photoBase64,
          'systemRole': old?.systemRole ?? item.systemRole,
          'roleKey': old?.roleKey ?? item.roleKey,
          'employmentType': isProbation ? 'probation' : item.employmentType,
          'probationStartDate':
              old?.probationStartDate ?? item.probationStartDate,
          'probationEndDate':
              old?.probationEndDate ?? item.probationEndDate,
          'agreementPdfName':
              old?.agreementPdfName ?? item.agreementPdfName,
          'agreementPdfUrl':
              old?.agreementPdfUrl ?? item.agreementPdfUrl,
          'agreementPdfBase64':
              old?.agreementPdfBase64 ?? item.agreementPdfBase64,
          'agreementPdfSizeBytes':
              old?.agreementPdfSizeBytes ?? item.agreementPdfSizeBytes,
          'activity': old?.activity ?? item.activity,
          'accessModules': old?.accessModules ?? item.accessModules,
        });
      }).toList();
      hasData = true;
      NotificationService.instance
          .checkAndNotifyProbationEnd(employees: _employees)
          .ignore();
      await _persist(account, token, revision, admin);
    } catch (exception) {
      if (current()) loadError = messageFor(exception);
    } finally {
      if (current()) {
        loading = false;
        _loading = null;
        notifyListeners();
      }
    }
  }

  Future<void> loadRoles() =>
      _token == null ? Future.value() : _rolesLoading ??= _loadRoles();

  Future<void> _loadRoles() async {
    final token = _token!;
    try {
      final fetched = await _repository.roles(token);
      if (token != _token) return;
      roles = fetched.isEmpty ? [EmployeeRole.operations] : fetched;
      roleError = null;
    } catch (exception) {
      if (token != _token) return;
      roleError =
          'Additional roles could not be loaded. ${messageFor(exception)}';
    } finally {
      if (token == _token) {
        _rolesLoading = null;
        notifyListeners();
      }
    }
  }

  Future<Employee?> loadDetails(String id) async {
    await load();
    final original = byId(id), token = _token;
    final revision = _revision;
    if (original?.backendId == null || token == null) return original;
    final detailed = await _repository.details(token, original!);
    if (token != _token || revision != _revision) return null;
    _upsert(detailed);
    await _persist(_session.user!.id, token, revision, canManage);
    notifyListeners();
    return detailed;
  }

  Future<EmployeeSaveResult> submit(EmployeeSubmission submission,
      {Employee? original}) async {
    if (!canManage || _token == null) {
      throw const ApiException('Administrator access is required.');
    }
    if (saving) {
      throw const ApiException('An employee change is already in progress.');
    }
    final token = _token!, account = _session.user!.id;
    final revision = ++_revision;
    _loading = null;
    loading = false;
    saving = true;
    notifyListeners();
    try {
      final result = await _repository.save(token, submission, original);
      if (token != _token || revision != _revision) {
        throw const ApiException(
            'Your session changed. Refresh the employee list before trying again.');
      }
      _upsert(result.employee);
      loadError = null;
      await _persist(account, token, revision, true);
      return result;
    } finally {
      if (token == _token && revision == _revision) {
        saving = false;
        notifyListeners();
      }
    }
  }

  void _upsert(Employee employee) {
    final index = _employees.indexWhere((item) => item.id == employee.id);
    _employees = [..._employees];
    if (index < 0) {
      _employees.add(employee);
    } else {
      _employees[index] = employee;
    }
    NotificationService.instance
        .checkAndNotifyProbationEnd(employees: _employees)
        .ignore();
  }

  Future<void> _persist(
      String account, String token, int revision, bool admin) {
    final snapshot = List<Employee>.from(_employees);
    _cacheWrites = _cacheWrites.then((_) async {
      if (token != _token || revision != _revision || !hasData) return;
      try {
        await _repository.saveCache(account, admin, snapshot);
        if (token == _token && revision == _revision) cacheError = null;
      } catch (_) {
        if (token == _token && revision == _revision) {
          cacheError =
              'Employees are saved on the server, but the offline cache could not be updated.';
        }
      }
    });
    return _cacheWrites;
  }

  Future<void> setActive(Employee employee, bool active) async {
    final current = await loadDetails(employee.id);
    if (current == null || current.roleKey == null) {
      throw const FormatException(
          'Refresh this employee before changing status.');
    }
    await submit(
        EmployeeSubmission(
            employee: Employee.fromJson({
              ...current.toJson(),
              'photoBase64': null,
              'status': active ? 'Active' : 'Inactive'
            }),
            roleKey: current.roleKey!,
            accessScope: current.accessScope ?? 'assigned'),
        original: current);
  }

  Future<void> updateEmploymentType(
    Employee employee,
    String type, {
    String? probationStartDate,
    String? probationEndDate,
  }) async {
    final updated = employee.copyWith(
      employmentType: type,
      probationStartDate: probationStartDate,
      probationEndDate: probationEndDate,
    );
    await submit(
      EmployeeSubmission(
        employee: updated,
        roleKey: employee.roleKey ?? EmployeeRole.operations.key,
        accessScope: employee.accessScope ?? 'assigned',
      ),
      original: employee,
    );
  }

  Future<void> attachAgreementPdf(
    Employee employee, {
    required String fileName,
    required String base64,
    required int sizeBytes,
  }) async {
    final updated = employee.copyWith(
      agreementPdfName: fileName,
      agreementPdfBase64: base64,
      agreementPdfSizeBytes: sizeBytes,
    );
    await submit(
      EmployeeSubmission(
        employee: updated,
        roleKey: employee.roleKey ?? EmployeeRole.operations.key,
        accessScope: employee.accessScope ?? 'assigned',
      ),
      original: employee,
    );
  }

  String _lifecycleId(Employee employee) {
    if (!canManage ||
        _token == null ||
        employee.backendId == null ||
        employee.id == _session.employeeId) {
      throw const FormatException(
          'Administrator access to another employee is required.');
    }
    return employee.backendId!;
  }

  Future<Map<String, dynamic>> offboardingSummary(Employee employee) async {
    final id = _lifecycleId(employee), token = _token!;
    final summary = await _repository.offboarding(token, id);
    if (token != _token) throw const FormatException('Your account changed.');
    return summary;
  }

  Future<void> reassignWorkload(Employee employee, Employee replacement,
      {bool leads = true,
      bool workItems = true,
      bool directReports = true}) async {
    final id = _lifecycleId(employee), token = _token!;
    if (replacement.backendId == null ||
        replacement.id == employee.id ||
        replacement.status != 'Active') {
      throw const FormatException('Choose another active employee.');
    }
    await _repository.reassignWorkload(token, id, replacement.backendId!,
        leads: leads, workItems: workItems, directReports: directReports);
    if (token != _token) throw const FormatException('Your account changed.');
    await load();
  }

  Future<void> suspendEmployee(Employee employee, bool suspend,
      {String reasonType = 'disciplinary', String reasonNote = ''}) async {
    final id = _lifecycleId(employee), token = _token!;
    await _repository.changeLifecycle(token, id, suspend,
        reasonType: reasonType, reasonNote: reasonNote);
    if (token != _token) throw const FormatException('Your account changed.');
    await load();
  }

  Future<EmployeeSaveResult> assignTeam(Employee employee, String name) async {
    if (!canManage) {
      throw const FormatException('Administrator access is required.');
    }
    final current = await loadDetails(employee.id);
    if (current == null || current.roleKey == null || name.trim().isEmpty) {
      throw const FormatException(
          'Refresh this employee before changing their team.');
    }
    return submit(
        EmployeeSubmission(
            employee: Employee.fromJson({
              ...current.toJson(),
              'team': name.trim(),
              'photoBase64': null
            }),
            roleKey: current.roleKey!,
            accessScope: current.accessScope ?? 'assigned'),
        original: current);
  }

  Future<EmployeeSaveResult> assignDepartment(
      Employee employee, String departmentId, String departmentName) async {
    if (!canManage) {
      throw const FormatException('Administrator access is required.');
    }
    final current = await loadDetails(employee.id);
    if (current == null || current.roleKey == null) {
      throw const FormatException(
          'Refresh this employee before changing their department.');
    }
    return submit(
        EmployeeSubmission(
            employee: Employee.fromJson({
              ...current.toJson(),
              'departmentId': departmentId,
              'department': departmentName,
              'photoBase64': null
            }),
            roleKey: current.roleKey!,
            accessScope: current.accessScope ?? 'assigned'),
        original: current);
  }

  Future<EmployeeSaveResult> assignManager(
      Employee employee, String? managerId, String? managerName) async {
    if (!canManage) {
      throw const FormatException('Administrator access is required.');
    }
    final current = await loadDetails(employee.id);
    if (current == null || current.roleKey == null) {
      throw const FormatException(
          'Refresh this employee before changing their manager.');
    }
    return submit(
        EmployeeSubmission(
            employee: Employee.fromJson({
              ...current.toJson(),
              'reportsToId': managerId,
              'reportsTo': managerName,
              'photoBase64': null
            }),
            roleKey: current.roleKey!,
            accessScope: current.accessScope ?? 'assigned'),
        original: current);
  }

  Future<EmployeeSaveResult> assignRole(
      Employee employee, String roleKey, String roleName) async {
    if (!canManage) {
      throw const FormatException('Administrator access is required.');
    }
    final current = await loadDetails(employee.id);
    if (current == null) {
      throw const FormatException(
          'Refresh this employee before changing their role.');
    }
    if (current.backendId == _session.user?.employeeId) {
      throw const FormatException(
          'You cannot change your own role or access scope.');
    }
    return submit(
        EmployeeSubmission(
            employee: Employee.fromJson({
              ...current.toJson(),
              'systemRole': roleName,
              'roleKey': roleKey,
              'photoBase64': null
            }),
            roleKey: roleKey,
            accessScope: current.accessScope ?? 'assigned'),
        original: current);
  }

  Future<void> save(Employee employee, {String? initialPassword}) async {
    if (_session.isAdmin && employee.id == _session.employeeId) {
      throw const FormatException('Super Admin profiles are read-only.');
    }
    throw const FormatException(
        'Use employee onboarding to update staff. Personal profile editing requires its profile API.');
  }

  /// Full self-profile data takes priority over the directory's summary rows.
  void applyCurrentProfile(Employee employee) {
    if (!_session.signedIn ||
        _session.isAdmin ||
        employee.id != _session.employeeId) {
      return;
    }
    _currentProfile = employee;
    notifyListeners();
  }

  Future<void> verifyAdminPassword(String password, {String? actorId}) async {
    if (!canManage || (actorId != null && actorId != _session.employeeId)) {
      throw const FormatException(
          'Sign in as administrator to manage passwords.');
    }
    await _session.verifyPassword(password);
  }

  Future<String?> revealEmployeePassword(
          String employeeId, String adminPassword) async =>
      null;

  Future<void> resetEmployeePassword(
          String employeeId, String newPassword, String adminPassword) async =>
      throw const FormatException(
          'The backend does not provide administrator password reset for employees.');

  Future<void> changePassword(String current, String password) =>
      _session.changePassword(current, password);

  static String messageFor(Object exception) => exception is FormatException
      ? exception.message
      : 'Unable to load employee data. Please try again.';

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }
}
