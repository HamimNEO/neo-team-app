import '../../domain/models/department.dart';
import '../datasources/department_api.dart';
import '../datasources/department_cache.dart';

class DepartmentRepository {
  const DepartmentRepository(
      {required DepartmentApi api, required DepartmentCache cache})
      : _api = api,
        _cache = cache;
  final DepartmentApi _api;
  final DepartmentCache _cache;

  Future<List<DepartmentItem>> list(String token, {required bool admin}) =>
      _api.list(token, admin: admin);

  Future<DepartmentItem> details(String token, String id) =>
      _api.details(token, id);

  Future<List<DepartmentItem>?> readCache(String accountId,
          {required bool admin}) =>
      _cache.read(accountId, admin: admin);

  Future<void> saveCache(String accountId, List<DepartmentItem> items,
          {required bool admin}) =>
      _cache.save(accountId, items, admin: admin);

  Future<DepartmentItem> create(String token,
          {required String name, required String code, required bool active}) =>
      _api.create(token, name: name, code: code, active: active);

  Future<DepartmentItem> update(String token, String id,
          {required String name, required String code, required bool active}) =>
      _api.update(token, id, name: name, code: code, active: active);

  Future<void> delete(String token, String id) => _api.delete(token, id);

  Future<void> assignMembers(String token, String id, List<int> employeeIds) =>
      _api.assignMembers(token, id, employeeIds);

  Future<void> removeMember(String token, String id, String employeeId) =>
      _api.removeMember(token, id, employeeId);
}
