import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/models/employee.dart';
import 'employee_store.dart';

class TeamGroup {
  final String id;
  final String name;
  final String leadName;
  final int memberCount;
  final String department;

  const TeamGroup({
    required this.id,
    required this.name,
    required this.leadName,
    required this.memberCount,
    required this.department,
  });
}

class DepartmentItem {
  final String id;
  final String name;
  final String leadName;
  final int memberCount;
  final int teamCount;
  final String description;
  final String status;
  final Color iconColor;

  const DepartmentItem({
    required this.id,
    required this.name,
    required this.leadName,
    required this.memberCount,
    required this.teamCount,
    required this.description,
    this.status = 'Active',
    required this.iconColor,
  });
}

const List<TeamGroup> mockTeams = [
  TeamGroup(
    id: 'team_sales',
    name: 'Hospitality Sales',
    leadName: 'Karim Hossain',
    memberCount: 6,
    department: 'Sales',
  ),
  TeamGroup(
    id: 'team_dev',
    name: 'NEONECY Dev',
    leadName: 'Md. Yeapas',
    memberCount: 4,
    department: 'Development',
  ),
  TeamGroup(
    id: 'team_marketing',
    name: 'Marketing Team',
    leadName: 'Razia Sultana',
    memberCount: 3,
    department: 'Marketing',
  ),
  TeamGroup(
    id: 'team_support',
    name: 'Support Team',
    leadName: 'Anika Tasnim',
    memberCount: 2,
    department: 'Support',
  ),
];

const List<DepartmentItem> mockDepartments = [
  DepartmentItem(
    id: 'dept_management',
    name: 'Management',
    leadName: 'Rahul Sharma',
    memberCount: 3,
    teamCount: 1,
    description: 'Executive management and strategy',
    iconColor: AppColors.success,
  ),
  DepartmentItem(
    id: 'dept_sales',
    name: 'Sales',
    leadName: 'Fatima Al Rashid',
    memberCount: 12,
    teamCount: 3,
    description: 'Hospitality sales, client acquisitions and revenue',
    iconColor: AppColors.warning,
  ),
  DepartmentItem(
    id: 'dept_marketing',
    name: 'Marketing',
    leadName: 'Chen Wei',
    memberCount: 5,
    teamCount: 2,
    description: 'Brand, campaigns and lead generation',
    iconColor: Color(0xFF30B0C7),
  ),
  DepartmentItem(
    id: 'dept_dev',
    name: 'Development',
    leadName: 'Arjun Singh',
    memberCount: 8,
    teamCount: 2,
    description: 'Software engineering, mobile app and backend API',
    iconColor: AppColors.brandLight,
  ),
  DepartmentItem(
    id: 'dept_support',
    name: 'Support',
    leadName: 'Priya Nair',
    memberCount: 6,
    teamCount: 2,
    description: 'Customer support and issue resolution',
    iconColor: AppColors.error,
  ),
];

List<Employee> get mockEmployees => EmployeeStore.instance.employees;

Employee getEmployeeById(String id) {
  return mockEmployees.firstWhere(
    (e) => e.id == id,
    orElse: () => throw StateError('Employee not found'),
  );
}

DepartmentItem getDepartmentById(String id) {
  return mockDepartments.firstWhere(
    (d) => d.id == id,
    orElse: () => mockDepartments.first,
  );
}
