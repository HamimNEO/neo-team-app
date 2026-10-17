import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/core/storage/preferences_store.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/features/team/data/datasources/employee_api.dart';
import 'package:neonecy_team_app/features/team/data/datasources/employee_cache.dart';
import 'package:neonecy_team_app/features/team/data/employee_api_mapper.dart';
import 'package:neonecy_team_app/features/team/data/repositories/employee_repository.dart';
import 'package:neonecy_team_app/features/team/domain/models/employee.dart';
import 'package:neonecy_team_app/features/team/domain/models/employee_salary.dart';
import 'package:neonecy_team_app/features/team/domain/models/employee_submission.dart';
import 'package:neonecy_team_app/features/team/domain/models/employee_role.dart';
import 'package:neonecy_team_app/features/team/presentation/widgets/add_employee_step3.dart';
import 'package:neonecy_team_app/features/team/presentation/widgets/employee_salary_draft.dart';
import 'package:neonecy_team_app/features/team/presentation/widgets/employee_salary_step.dart';

EmployeeSubmission submission({String? photo}) => EmployeeSubmission(
    employee: Employee(
        id: '',
        name: 'New Employee',
        email: 'new@example.test',
        phone: '',
        designation: 'Executive',
        department: 'Operations',
        departmentId: '3',
        team: 'My new team',
        systemRole: 'Operations',
        status: 'Active',
        avatarInitials: 'NE',
        joinedDate: '2026-10-11',
        employeeCode: 'NEC-EMP-002',
        photoBase64: photo,
        companyMealEnabled: true,
        totalMealCost: 300000,
        isMealFree: false,
        mealCoPayPercent: 20,
        hasRotationalReserve: true,
        rotationalReserveAmount: 200000,
        salary: const EmployeeSalary(
            basic: 2000025,
            additions: [SalaryComponent(name: 'Allowance', amount: 250050)],
            deductions: [SalaryComponent(name: 'Deduction', amount: 50075)],
            effectiveDate: '2026-10-11',
            paymentMethod: 'Cash',
            notes: 'Test only')),
    roleKey: 'TEAM_OPERATIONS',
    accessScope: 'assigned',
    password: 'Temporary123!');

Map<String, dynamic> backendRecord() => {
      'id': 7,
      'name': 'New Employee',
      'email': 'new@example.test',
      'employee_code': 'NEC-EMP-002',
      'designation': 'Executive',
      'department_id': 3,
      'department_name': 'Operations',
      'employment_status': 'active',
      'is_active': true,
      'team': 'My new team',
      'joining_date': '2026-10-11',
      'salary_enabled': true,
      'basic_salary': '20000.25',
      'currency': 'BDT',
      'salary_additions': '[{"name":"Allowance","amount":2500.5}]',
      'salary_deductions': '[{"name":"Deduction","amount":500.75}]',
      'pay_frequency': 'monthly',
      'payment_method': 'cash',
      'salary_payment_day': 1,
      'company_meal_enabled': true,
      'company_meal_cost': '3000',
      'company_meal_contribution': '2400',
      'rotational_reserve_enabled': true,
      'rotational_reserve_deduction': '2000'
    };
http.Response response(Object object, [int status = 200]) =>
    http.Response(jsonEncode(object), status);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('onboarding sends real placement, credentials and exact payroll amounts',
      () async {
    final input = submission();
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/team-operations/team/employees');
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map;
          expect(body['department_id'], '3');
          expect(body['role_key'], 'TEAM_OPERATIONS');
          expect(body['password'], 'Temporary123!');
          expect(body['basic_salary'], '20000.25');
          expect(body['salary_additions'][0]['amount'], '2500.50');
          expect(body['salary_deductions'][0]['amount'], '500.75');
          expect(body['company_meal_contribution'], '2400.00');
          expect(body['rotational_reserve_deduction'], '2000.00');
          return response({'employee': backendRecord()});
        }));
    addTearDown(client.close);
    final result = await EmployeeApi(client).create('token', input);
    expect(result['id'], 7);
  });

  test(
      'photo upload uses multipart and nested payroll fields on the HTTPS host',
      () async {
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          expect(request.headers['Content-Type'],
              startsWith('multipart/form-data;'));
          expect(request.headers['Authorization'], 'Bearer token');
          final body = utf8.decode(request.bodyBytes, allowMalformed: true);
          expect(body, contains('name="photo"; filename="employee.png"'));
          expect(body.toLowerCase(), contains('content-type: image/png'));
          expect(body, contains('name="salary_additions[0][amount]"'));
          expect(body, contains('2500.50'));
          expect(body, contains('name="company_meal_enabled"'));
          return response({'employee': backendRecord()});
        }));
    addTearDown(client.close);
    await EmployeeApi(client).create('token',
        submission(photo: base64Encode(Uint8List.fromList([137, 80, 78, 71]))));
  });

  test(
      'API salary strings/arrays round-trip without passwords in the account cache',
      () async {
    final employee =
        employeeFromApi(backendRecord(), 'https://example.test/api');
    expect(employee.backendId, '7');
    expect(employee.salary!.net, 2200000);
    expect(employee.mealEmployeePayAmount, 60000);
    const cache = EmployeeCache(PreferencesStore());
    await cache.save('usr_1', true, [employee]);
    expect((await cache.read('usr_1', true))!.single.salary!.basic, 2000025);
    expect(await cache.read('usr_2', true), isNull);
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect(prefs.getString(key), isNot(contains('Temporary123!')));
    }
  });

  test('a successful create stays successful when the follow-up refresh fails',
      () async {
    var posts = 0;
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            posts++;
            return response({'employee': backendRecord()});
          }
          return response({'message': 'Server Error'}, 500);
        }));
    addTearDown(client.close);
    final repository = EmployeeRepository(
        api: EmployeeApi(client),
        cache: const EmployeeCache(PreferencesStore()),
        baseUrl: () => 'https://example.test/api');
    final result = await repository.save('token', submission(), null);
    expect(result.employee.id, 'api_emp_7');
    expect(result.warning, contains('Employee saved'));
    expect(posts, 1);
  });

  test('uploaded image cache follows the confirmed backend photo path',
      () async {
    var path = 'team-operations/profiles/saved.png';
    final photo = base64Encode(Uint8List.fromList([137, 80, 78, 71]));
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          final record = {...backendRecord(), 'photo': path};
          if (request.url.path ==
              '/api/super-admin/team-operations/employees') {
            return response({
              'data': [record],
              'current_page': 1,
              'last_page': 1
            });
          }
          return response({'employee': record});
        }));
    addTearDown(client.close);
    final repository = EmployeeRepository(
        api: EmployeeApi(client),
        cache: const EmployeeCache(PreferencesStore()),
        baseUrl: () => 'https://example.test/api');
    final saved =
        await repository.save('token', submission(photo: photo), null);
    expect(saved.employee.photoBase64, photo);
    expect(
        (await repository.details('token', saved.employee)).photoBase64, photo);
    await repository.saveCache('usr_1', true, [saved.employee]);
    expect(
        (await repository.readCache('usr_1', true))!.single.photoBase64, photo);
    path = 'team-operations/profiles/replaced.png';
    expect((await repository.details('token', saved.employee)).photoBase64,
        isNull);
  });

  testWidgets('review fits a phone and edit salary offers no misleading inputs',
      (tester) async {
    final password = TextEditingController(), confirm = TextEditingController();
    final draft = EmployeeSalaryDraft(submission().employee.salary);
    addTearDown(password.dispose);
    addTearDown(confirm.dispose);
    addTearDown(draft.dispose);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final theme = ThemeData(extensions: const [NecColors.light()]);
    await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: AddEmployeeStep3(
          selectedRole: 'TEAM_OPERATIONS',
          employeeName: 'New Employee',
          employeeEmail: 'new@example.test',
          employeeCode: 'NEC-EMP-002',
          onRoleChanged: (_) {},
          onSubmit: () {},
          isLoading: false,
          needsPassword: true,
          credentialsFormKey: GlobalKey<FormState>(),
          passwordController: password,
          confirmPasswordController: confirm,
          roles: const [EmployeeRole.operations],
          onRetryRoles: () {},
          accessScope: 'assigned',
          onAccessScopeChanged: (_) {},
        ))));
    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Full Access'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: EmployeeSalaryStep(
                draft: draft,
                formKey: GlobalKey<FormState>(),
                onContinue: () {},
                editable: false))));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
