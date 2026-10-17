import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'profile_fixture.dart';
import 'package:neonecy_team_app/features/team/data/employee_store.dart';

final _client = MockClient((request) async {
  final employee = {
    'id': 12,
    'name': 'Employee One',
    'email': 'staff@example.test',
    'employee_code': 'NEC-EMP-012',
    'designation': 'Executive',
    'team': 'Platform',
    'department_id': 1,
    'department_name': 'Operations',
    'employment_status': 'active',
    'is_active': true,
    'joining_date': '2026-10-01',
    'role': {'key': 'TEAM_OPERATIONS', 'name': 'Operations'}
  };
  if (request.url.path.endsWith('/super-admin/team-operations/employees')) {
    return http.Response(
        jsonEncode({
          'current_page': 1,
          'last_page': 1,
          'data': [employee]
        }),
        200);
  }
  if (request.url.path.endsWith('/team/employees/12')) {
    return http.Response(
        jsonEncode({
          'employee': employee,
          'access': {
            'role': employee['role'],
            'access_scope': 'assigned',
            'modules': []
          },
          'activity': []
        }),
        200);
  }
  if (request.url.path.endsWith('/departments')) {
    return http.Response(
        jsonEncode({'current_page': 1, 'last_page': 1, 'data': []}), 200);
  }

  if (request.url.path.endsWith('/sign-out')) return http.Response('{}', 200);
  if (request.url.path.endsWith('/profile')) {
    return http.Response(jsonEncode(profileJson()), 200);
  }
  if (request.url.path.endsWith('/auth/login') &&
      (jsonDecode(request.body) as Map)['password'] == 'incorrect') {
    return http.Response('{"message":"Invalid credentials."}', 401);
  }
  return http.Response(
      jsonEncode({
        'token': 'widget-test-token',
        'expires_at':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'user': {
          'id': 'usr_test',
          'name': 'Test Admin',
          'email': 'admin@example.test',
          'role': 'SUPER_ADMIN',
          'is_super_admin': true,
          'modules': ['leads', 'tasks', 'team'],
          'employee': {'id': 0, 'access_scope': 'all'},
          'must_change_password': false,
        },
      }),
      200);
});

Future<T> withWidgetApiClient<T>(Future<T> Function() action) =>
    http.runWithClient(action, () => _client);

/// Gives shell widgets an authenticated API identity without real networking.
Future<void> signInWidgetAdmin() async {
  SharedPreferences.setMockInitialValues({});
  dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
  await http.runWithClient(
    () async {
      await AuthSession.instance.signIn('admin@example.test', 'test-password');
      await EmployeeStore.instance.load();
    },
    () => _client,
  );
}
