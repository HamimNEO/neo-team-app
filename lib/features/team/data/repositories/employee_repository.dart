import '../../domain/models/employee.dart';
import '../../domain/models/employee_role.dart';
import '../../domain/models/employee_submission.dart';
import '../datasources/employee_api.dart';
import '../datasources/employee_cache.dart';
import '../employee_api_mapper.dart';

class EmployeeSaveResult {
  const EmployeeSaveResult(this.employee, {this.warning});

  final Employee employee;
  final String? warning;
}

class EmployeeRepository {
  const EmployeeRepository(
      {required EmployeeApi api,
      required EmployeeCache cache,
      required String Function() baseUrl})
      : _api = api,
        _cache = cache,
        _baseUrl = baseUrl;
  final EmployeeApi _api;
  final EmployeeCache _cache;
  final String Function() _baseUrl;

  Future<Map<String, dynamic>> offboarding(String token, String id) =>
      _api.offboarding(token, id);

  Future<void> reassignWorkload(String token, String id, String replacement,
          {bool leads = true,
          bool workItems = true,
          bool directReports = true}) =>
      _api.reassignWorkload(token, id, replacement,
          leads: leads, workItems: workItems, directReports: directReports);

  Future<void> changeLifecycle(String token, String id, bool suspended,
          {String reasonType = 'disciplinary', String reasonNote = ''}) =>
      _api.changeLifecycle(token, id, suspended,
          reasonType: reasonType, reasonNote: reasonNote);

  Future<List<Employee>?> readCache(String account, bool admin) =>
      _cache.read(account, admin);

  Future<void> saveCache(
          String account, bool admin, List<Employee> employees) =>
      _cache.save(account, admin, employees);

  Future<List<EmployeeRole>> roles(String token) => _api.roles(token);

  Future<List<Employee>> list(String token, bool admin) async =>
      (await _api.list(token, admin: admin))
          .map((record) => employeeFromApi(record, _baseUrl()))
          .toList();

  Future<Employee> details(String token, Employee original) async {
    final detail = await _api.details(token, original.backendId!);
    final mapped = employeeFromApi(detail, _baseUrl());
    return Employee.fromJson({
      ...original.toJson(),
      ...mapped.toJson(),
      'photoBase64': original.photoUrl == mapped.photoUrl
          ? original.photoBase64 ?? mapped.photoBase64
          : mapped.photoBase64,
      'salary':
          detail.containsKey('salary') || detail.containsKey('salary_enabled')
              ? mapped.salary?.toJson()
              : null,
      'benefitsKnown': original.benefitsKnown,
      'companyMealEnabled': original.companyMealEnabled,
      'totalMealCost': original.totalMealCost,
      'isMealFree': original.isMealFree,
      'mealCoPayPercent': original.mealCoPayPercent,
      'hasRotationalReserve': original.hasRotationalReserve,
      'rotationalReserveAmount': original.rotationalReserveAmount,
      'reportsToId': original.reportsToId,
      'employmentType': mapped.employmentType,
      'probationStartDate':
          mapped.probationStartDate ?? original.probationStartDate,
      'probationEndDate': mapped.probationEndDate ?? original.probationEndDate,
      'agreementPdfName': mapped.agreementPdfName ?? original.agreementPdfName,
      'agreementPdfUrl': mapped.agreementPdfUrl ?? original.agreementPdfUrl,
      'agreementPdfBase64':
          original.agreementPdfBase64 ?? mapped.agreementPdfBase64,
      'agreementPdfSizeBytes':
          mapped.agreementPdfSizeBytes ?? original.agreementPdfSizeBytes,
    });
  }

  Future<EmployeeSaveResult> save(
      String token, EmployeeSubmission submission, Employee? original) async {
    var record = original == null
        ? await _api.create(token, submission)
        : await _api.update(token, original.backendId!, submission);
    String? warning;
    if (original != null &&
        (original.roleKey != submission.roleKey ||
            original.accessScope != submission.accessScope)) {
      try {
        final access = await _api.setAccess(token, original.backendId!,
            submission.roleKey, submission.accessScope);
        record = {
          ...record,
          'role': access['role'],
          'access_scope': access['access_scope']
        };
      } catch (exception) {
        warning =
            'Employee details saved, but the access change failed. ${_message(exception)}';
      }
    }
    var employee = employeeFromApi(record, _baseUrl());
    try {
      final directory = await _api.list(token, admin: true);
      final raw = directory
          .where((item) => item['id'].toString() == record['id'].toString())
          .firstOrNull;
      if (raw != null) {
        employee = employeeFromApi(
            {...raw, if (record['role'] != null) 'role': record['role']},
            _baseUrl());
      }
      employee = await details(token, employee);
    } catch (exception) {
      warning = [
        if (warning != null) warning,
        'Employee saved. Some details could not be refreshed. ${_message(exception)}'
      ].join(' ');
    }
    final photo = submission.employee.photoBase64;
    employee = Employee.fromJson({
      ...employee.toJson(),
      if (photo != null) 'photoBase64': photo,
    });
    if (original?.photoUrl == employee.photoUrl &&
        original?.photoBase64 != null &&
        photo == null) {
      employee = Employee.fromJson(
          {...employee.toJson(), 'photoBase64': original!.photoBase64});
    }
    return EmployeeSaveResult(employee, warning: warning);
  }

  static String _message(Object exception) =>
      exception is FormatException ? exception.message : 'Please refresh.';
}
