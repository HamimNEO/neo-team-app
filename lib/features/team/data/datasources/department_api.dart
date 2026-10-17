import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/config/app_config.dart';
import '../employee_api_mapper.dart';
import '../../domain/models/department.dart';

class DepartmentApi {
  const DepartmentApi(this._client);

  final ApiClient _client;

  Future<List<DepartmentItem>> list(String token, {required bool admin}) async {
    if (!admin) {
      final response = await _client.get(ApiEndpoints.team,
          queryParameters: {'tab': 'departments'}, token: token);
      return _records(response['departments'] ?? response['data']);
    }
    final items = <DepartmentItem>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _client.get(ApiEndpoints.departments,
          queryParameters: {'per_page': '100', 'page': '$page'}, token: token);
      final currentPage = response['current_page'];
      final last = response['last_page'];
      if (currentPage != page || last is! int || last < page) {
        throw const ApiException(
            'The server returned invalid department pagination.');
      }
      lastPage = last;
      items.addAll(_records(response['data']));
      page++;
    } while (page <= lastPage);
    final unique = {for (final item in items) item.id: item};
    if (unique.length != items.length) {
      throw const ApiException(
          'The department list changed while loading. Please refresh.');
    }
    return items;
  }

  List<DepartmentItem> _records(dynamic value) {
    if (value is! List || value.any((record) => record is! Map)) {
      throw const ApiException(
          'The server returned an invalid department list.');
    }
    return value
        .map((record) =>
            DepartmentItem.fromJson(Map<String, dynamic>.from(record as Map)))
        .toList();
  }

  Future<DepartmentItem> create(String token,
          {required String name,
          required String code,
          required bool active}) async =>
      _department(await _client.post(ApiEndpoints.departments,
          token: token,
          body: {'name': name, 'code': code, 'is_active': active}));

  Future<DepartmentItem> update(String token, String id,
      {required String name,
      required String code,
      required bool active}) async {
    final result = _department(await _client.patch(ApiEndpoints.department(id),
        token: token, body: {'name': name, 'code': code, 'is_active': active}));
    if (result.id != id) {
      throw const ApiException(
          'The server returned a different department. Please refresh.');
    }
    return result;
  }

  Future<void> delete(String token, String id) async {
    await _client.delete(ApiEndpoints.department(id), token: token);
  }

  Future<DepartmentItem> details(String token, String id) async {
    final response =
        await _client.get(ApiEndpoints.departmentDetails(id), token: token);
    final result = _department(response);
    if (result.id != id) {
      throw const ApiException('The server returned a different department.');
    }
    return DepartmentItem.fromJson({
      ...result.toJson(),
      if (response['members'] is List)
        'members': (response['members'] as List)
            .map((member) => employeeFromApi(
                    Map<String, dynamic>.from(member as Map),
                    AppConfig.apiBaseUrl)
                .toJson())
            .toList(),
    });
  }

  Future<void> assignMembers(
      String token, String id, List<int> employeeIds) async {
    await _client.post(ApiEndpoints.departmentMembers(id),
        token: token, body: {'employee_ids': employeeIds});
  }

  Future<void> removeMember(String token, String id, String employeeId) async {
    await _client.delete(ApiEndpoints.departmentMember(id, employeeId),
        token: token);
  }

  DepartmentItem _department(Map<String, dynamic> response) {
    if (response['department'] is! Map) {
      throw const ApiException(
          'The server returned an invalid department. Please refresh.');
    }
    return DepartmentItem.fromJson(
        Map<String, dynamic>.from(response['department'] as Map));
  }
}
