import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/core/network/api_exception.dart';
import 'package:neonecy_team_app/core/storage/preferences_store.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/team/data/datasources/department_api.dart';
import 'package:neonecy_team_app/features/team/data/datasources/department_cache.dart';
import 'package:neonecy_team_app/features/team/data/department_store.dart';
import 'package:neonecy_team_app/features/team/data/repositories/department_repository.dart';
import 'package:neonecy_team_app/features/team/presentation/departments_screen.dart';
import 'package:neonecy_team_app/features/team/presentation/widgets/create_department_sheet.dart';
import '../auth/auth_integration_test.dart'
    show createSession, response, sessionJson;

Map<String, dynamic> record(int id,
        {String name = 'Operations', bool active = true}) =>
    {'id': id, 'name': name, 'code': 'OPS', 'is_active': active};
Map<String, dynamic> page(List<Map<String, dynamic>> records,
        {int current = 1, int last = 1}) =>
    {'current_page': current, 'last_page': last, 'data': records};

DepartmentStore storeFor(
    AuthSession session, Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(
      baseUrl: () => 'https://example.test/api', client: MockClient(handler));
  addTearDown(client.close);
  final store = DepartmentStore(
      session: session,
      repository: DepartmentRepository(
          api: DepartmentApi(client),
          cache: const DepartmentCache(PreferencesStore())));
  addTearDown(store.dispose);
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('list uses HTTPS query parameters and retrieves every page', () async {
    final pages = <String>[];
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token');
          expect(request.url.scheme, 'https');
          expect(request.url.queryParameters['per_page'], '100');
          pages.add(request.url.queryParameters['page']!);
          final current = int.parse(pages.last);
          return response({
            ...page([record(current)], current: current, last: 2),
            'next_page_url': 'http://untrusted.example/departments?page=2'
          });
        }));
    addTearDown(client.close);
    final items = await DepartmentApi(client).list('token', admin: true);
    expect(pages, ['1', '2']);
    expect(items.map((d) => d.id), ['1', '2']);
    expect(items.first.memberCount, isNull);
    expect(items.first.leadName, isNull);
  });

  test('writes use documented methods, payloads and server IDs', () async {
    final methods = <String>[];
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient((request) async {
          methods.add(request.method);
          expect(request.headers['Authorization'], 'Bearer token');
          if (request.method == 'DELETE') {
            expect(request.url.path, endsWith('/departments/17'));
            return http.Response('', 204);
          }
          expect(jsonDecode(request.body), {
            'name': 'Operations',
            'code': 'OPS',
            'is_active': request.method == 'POST',
          });
          return response(
              {'department': record(17, active: request.method == 'POST')});
        }));
    addTearDown(client.close);
    final api = DepartmentApi(client);
    final created = await api.create('token',
        name: 'Operations', code: 'OPS', active: true);
    expect(created.id, '17');
    final edited = await api.update('token', created.id,
        name: 'Operations', code: 'OPS', active: false);
    expect(edited.isActive, isFalse);
    await api.delete('token', created.id);
    expect(methods, ['POST', 'PATCH', 'DELETE']);
  });

  test('delete rejection retains the real department and its cache', () async {
    final session = createSession((_) async => response(sessionJson()));
    await session.signIn('admin@example.test', 'password');
    final store = storeFor(
        session,
        (request) async => request.method == 'DELETE'
            ? response({
                'message': 'Reassign employees before deleting this department.'
              }, 422)
            : response(page([record(3)])));
    await store.load();
    await expectLater(
        store.delete('3'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', contains('Reassign employees'))));
    expect(store.byId('3'), isNotNull);
    final cached =
        await const DepartmentCache(PreferencesStore()).read('usr_1');
    expect(cached!.single.id, '3');
  });

  test('a stale list response cannot undo a confirmed department update',
      () async {
    final session = createSession((_) async => response(sessionJson()));
    await session.signIn('admin@example.test', 'password');
    final pending = Completer<http.Response>();
    var reads = 0;
    final store = storeFor(session, (request) async {
      if (request.method == 'PATCH') {
        return response({'department': record(3, name: 'Growth')});
      }
      if (++reads == 1) return response(page([record(3)]));
      return pending.future;
    });
    await store.load();
    final loading = store.load();
    await store.save(
        department: store.byId('3'), name: 'Growth', code: 'OPS', active: true);
    pending.complete(response(page([record(3)])));
    await loading;
    expect(store.byId('3')!.name, 'Growth');
    expect(
        (await const DepartmentCache(PreferencesStore()).read('usr_1'))!
            .single
            .name,
        'Growth');
    await session.signOut();
    expect(store.departments, isEmpty);
  });

  testWidgets('empty directory and editable form fit a phone without demo data',
      (tester) async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://example.test/api');
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return response(sessionJson());
      }
      if (request.url.path.endsWith('/departments')) return response(page([]));
      return response({});
    });
    await http.runWithClient(
        () => AuthSession.instance.signIn('admin@example.test', 'password'),
        () => client);
    final theme = ThemeData(extensions: const [NecColors.light()]);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(
          MaterialApp(theme: theme, home: const DepartmentsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('No departments yet.'), findsOneWidget);
      expect(find.text('Marketing'), findsNothing);
      await tester.tap(find.text('+ New'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateDepartmentSheet), findsOneWidget);
      expect(find.text('DEPARTMENT CODE *'), findsOneWidget);
      expect(find.text('DEPARTMENT LEAD'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
    await AuthSession.instance.signOut();
  });
}
