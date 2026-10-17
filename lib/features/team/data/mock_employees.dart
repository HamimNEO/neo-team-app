import '../domain/models/employee.dart';
import '../domain/models/team_group.dart';
import 'employee_store.dart';
import 'team_store.dart';
export '../domain/models/team_group.dart';

List<TeamGroup> get mockTeams => TeamStore.instance.teams;

List<Employee> get mockEmployees => EmployeeStore.instance.employees;

Employee getEmployeeById(String id) =>
    mockEmployees.firstWhere((e) => e.id == id,
        orElse: () => throw StateError('Employee not found'));
