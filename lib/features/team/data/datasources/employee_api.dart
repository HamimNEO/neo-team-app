import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/employee_role.dart';
import '../../domain/models/employee_submission.dart';

class EmployeeApi {
  const EmployeeApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> offboarding(String token, String id) =>
      _client.get(ApiEndpoints.employeeLifecycle(id, 'offboarding-summary'),
          token: token);

  Future<void> reassignWorkload(String token, String id, String replacement,
      {bool leads = true,
      bool workItems = true,
      bool directReports = true}) async {
    await _client.post(ApiEndpoints.employeeLifecycle(id, 'reassign-workload'),
        token: token,
        body: {
          'replacement_employee_id': int.parse(replacement),
          'leads': leads,
          'work_items': workItems,
          'direct_reports': directReports
        });
  }

  Future<void> changeLifecycle(String token, String id, bool suspended,
      {String reasonType = 'disciplinary', String reasonNote = ''}) async {
    await _client.post(
        ApiEndpoints.employeeLifecycle(
            id, suspended ? 'suspend' : 'reactivate'),
        token: token,
        body: suspended
            ? {'reason_type': reasonType, 'reason_note': reasonNote}
            : <String, dynamic>{});
  }

  Future<List<Map<String, dynamic>>> list(String token,
      {required bool admin}) async {
    if (!admin) {
      final result = await _client.get(ApiEndpoints.team,
          token: token, queryParameters: {'tab': 'employees'});
      return _records(result['employees'] ?? result['data']);
    }
    final records = <Map<String, dynamic>>[];
    var page = 1, lastPage = 1;
    do {
      final result = await _client.get(ApiEndpoints.employees,
          token: token, queryParameters: {'per_page': '100', 'page': '$page'});
      if (result['current_page'] != page ||
          result['last_page'] is! int ||
          result['last_page'] < page) {
        throw const ApiException(
            'The server returned invalid employee pagination.');
      }
      lastPage = result['last_page'] as int;
      records.addAll(_records(result['data']));
      page++;
    } while (page <= lastPage);
    if ({for (final item in records) item['id']}.length != records.length) {
      throw const ApiException(
          'The employee list changed while loading. Please refresh.');
    }
    return records;
  }

  List<Map<String, dynamic>> _records(dynamic value) {
    if (value is! List || value.any((item) => item is! Map)) {
      throw const ApiException('The server returned an invalid employee list.');
    }
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> details(String token, String id) async {
    final result = await _client.get(ApiEndpoints.employee(id), token: token);
    final employee = _employee(result);
    if (employee['id'].toString() != id) {
      throw const ApiException('The server returned a different employee.');
    }
    final access = result['access'];
    return {
      ...employee,
      'activity': result['activity'] ?? [],
      if (access is Map) ...{
        'role': access['role'],
        'access_scope': access['access_scope'],
        'access_modules': access['modules'],
      }
    };
  }

  Future<List<EmployeeRole>> roles(String token) async {
    final result = await _client.get(ApiEndpoints.roles, token: token);
    return _records(result['roles'] ?? result['data'])
        .map(EmployeeRole.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> create(
          String token, EmployeeSubmission submission) async =>
      _employee(await _write(token, '/team-operations/employees',
          submission.createPayload(), submission.employee.photoBase64,
          agreement: submission.employee.agreementPdfBase64,
          agreementName: submission.employee.agreementPdfName));

  Future<Map<String, dynamic>> update(
      String token, String id, EmployeeSubmission submission) async {
    final record = _employee(await _write(token, ApiEndpoints.employee(id),
        submission.profilePayload(), submission.employee.photoBase64,
        patch: true,
        agreement: submission.employee.agreementPdfBase64,
        agreementName: submission.employee.agreementPdfName));
    if (record['id'].toString() != id) {
      throw const ApiException('The server returned a different employee.');
    }
    return record;
  }

  Future<Map<String, dynamic>> getAccess(String token, String id) async {
    final response =
        await _client.get(ApiEndpoints.employeeAccess(id), token: token);
    return response;
  }

  Future<Map<String, dynamic>> setAccess(
      String token, String id, String role, String scope) async {
    final response = await _client.put(ApiEndpoints.employeeAccess(id),
        token: token, body: {'role_key': role, 'access_scope': scope});
    if (response['access'] is! Map) {
      throw const ApiException('Unable to confirm the saved employee access.');
    }
    return Map<String, dynamic>.from(response['access'] as Map);
  }

  Future<Map<String, dynamic>> updateStatus(
      String token, String id, String status) async {
    final response = await _client.patch(
      ApiEndpoints.employee(id),
      token: token,
      body: {'employment_status': status},
    );
    return _employee(response);
  }

  Future<Map<String, dynamic>> _write(
      String token, String path, Map<String, dynamic> body, String? photo,
      {bool patch = false, String? agreement, String? agreementName}) {
    if (photo == null && agreement == null) {
      return patch
          ? _client.patch(path, body: body, token: token)
          : _client.post(path, body: body, token: token);
    }
    final fields = <String, String>{if (patch) '_method': 'PATCH'};
    void flatten(String key, dynamic value) {
      if (value is List) {
        for (var index = 0; index < value.length; index++) {
          flatten('$key[$index]', value[index]);
        }
      } else if (value is Map) {
        for (final entry in value.entries) {
          flatten('$key[${entry.key}]', entry.value);
        }
      } else {
        fields[key] = value == null
            ? ''
            : value is bool
                ? (value ? '1' : '0')
                : value.toString();
      }
    }

    body.forEach(flatten);
    return _client.multipart(path, fields: fields, token: token, files: [
      if (photo != null)
        ApiUpload(
            field: 'photo',
            bytes: base64Decode(photo),
            filename: 'employee.png'),
      if (agreement != null)
        ApiUpload(
            field: 'agreement_pdf',
            bytes: base64Decode(agreement),
            filename: agreementName ?? 'agreement.pdf',
            mimeType: 'application/pdf')
    ]);
  }

  Map<String, dynamic> _employee(Map<String, dynamic> response) {
    if (response['employee'] is! Map) {
      throw const ApiException(
          'The server returned an invalid employee. Refresh the list before retrying.');
    }
    return Map<String, dynamic>.from(response['employee'] as Map);
  }
}
