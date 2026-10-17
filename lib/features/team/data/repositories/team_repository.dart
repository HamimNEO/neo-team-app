import '../../domain/models/team_group.dart';
import '../employee_api_mapper.dart';
import '../datasources/team_api.dart';
import '../datasources/team_cache.dart';

class TeamRepository {
  const TeamRepository(
      {required this.api, required this.cache, required this.baseUrl});

  final TeamApi api;
  final TeamCache cache;
  final String Function() baseUrl;

  Future<TeamDetail> update(
      String token, String id, Map<String, dynamic> body) async {
    await api.update(token, id, body);
    return details(token, id);
  }

  TeamGroup _map(Map<String, dynamic> record) {
    final name = record['name'], count = record['member_count'];
    if (name is! String || name.isEmpty || count is! int) {
      throw const FormatException('The server returned an invalid team.');
    }
    final work = record['work_overview'];
    return TeamGroup(
        name: name,
        backendId: record['id']?.toString(),
        memberCount: count,
        department: (record['department_names'] as List? ?? []).join(' · '),
        description: record['description'] as String?,
        lead: record['lead'] is Map
            ? employeeFromApi(
                Map<String, dynamic>.from(record['lead'] as Map), baseUrl())
            : null,
        workOverview: work is Map ? Map<String, int>.from(work) : null);
  }

  Future<List<TeamGroup>> list(String token) async =>
      (await api.list(token)).map(_map).toList();

  Future<TeamDetail> details(String token, String name) async {
    final result = await api.details(token, name);
    final team = _map(Map<String, dynamic>.from(result['team'] as Map));
    if (team.name != name && team.backendId != name) {
      throw const FormatException('The server returned a different team.');
    }
    return TeamDetail(
        team,
        (result['members'] as List)
            .map((r) =>
                employeeFromApi(Map<String, dynamic>.from(r as Map), baseUrl()))
            .toList());
  }

  Future<TeamGroup> create(String token, Map<String, dynamic> payload) async {
    final response = await api.create(token, payload);
    if (response['team'] is! Map) {
      throw const FormatException(
          'The server did not return the created team.');
    }
    final record = Map<String, dynamic>.from(response['team'] as Map);
    if (record['member_count'] is! int) {
      return (await details(token, (record['id'] ?? record['name']).toString()))
          .team;
    }
    return _map(record);
  }

  Future<void> delete(String token, String id) => api.delete(token, id);
}
