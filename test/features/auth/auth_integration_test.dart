import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/core/network/api_exception.dart';
import 'package:neonecy_team_app/core/storage/preferences_store.dart';
import 'package:neonecy_team_app/features/auth/data/datasources/auth_api.dart';
import 'package:neonecy_team_app/features/auth/data/datasources/auth_session_cache.dart';
import 'package:neonecy_team_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/team/data/auth_employee_mapper.dart';

Map<String, dynamic> userJson({bool admin = true, bool mustChange = false}) => {
      'id': admin ? 'usr_1' : 'usr_2',
      'name': admin ? 'Super Admin' : 'Employee One',
      'email': admin ? 'admin@example.test' : 'staff@example.test',
      'phone': null,
      'role': admin ? 'SUPER_ADMIN' : 'EMPLOYEE',
      'is_super_admin': admin,
      'modules': admin ? ['leads', 'tasks', 'team'] : ['tasks'],
      'employee': {
        'id': admin ? 0 : 12,
        'code': admin ? 'SUPER-ADMIN' : 'EMP-012',
        'designation': admin ? 'Super Admin' : 'Executive',
        'department': null,
        'team': 'Platform',
        'access_scope': admin ? 'all' : 'assigned',
      },
      'must_change_password': mustChange,
    };

Map<String, dynamic> sessionJson({
  bool admin = true,
  bool mustChange = false,
  String token = 'test-token',
  DateTime? expiry,
}) =>
    {
      'token': token,
      'refresh_token': 'not-persisted',
      'expires_at': (expiry ?? DateTime.now().add(const Duration(hours: 1)))
          .toIso8601String(),
      'user': userJson(admin: admin, mustChange: mustChange),
    };

AuthSession createSession(
    Future<http.Response> Function(http.Request) handler) {
  late AuthSession session;
  final client = ApiClient(
    baseUrl: () => 'https://example.test/api',
    client: MockClient(handler),
    accessToken: () => session.accessToken,
    onUnauthorized: (token) => session.invalidate(token),
  );
  session = AuthSession(
      repository: AuthRepositoryImpl(
    api: AuthApi(client),
    cache: const AuthSessionCache(PreferencesStore()),
  ));
  addTearDown(session.dispose);
  addTearDown(client.close);
  return session;
}

http.Response response(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('login uses documented JSON and caches identity/token without passwords',
      () async {
    final session = createSession((request) async {
      expect(request.url.toString(),
          'https://example.test/api/team-operations/auth/login');
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], isNull);
      expect(request.headers['User-Agent'], 'NEC-Team-App/1.0');
      expect(jsonDecode(request.body),
          {'login': 'admin@example.test', 'password': 'test#password '});
      return response(sessionJson());
    });
    await session.signIn(' admin@example.test ', 'test#password ');
    expect(session.signedIn, isTrue);
    expect(session.isAdmin, isTrue);
    expect(session.user!.employeeId, '0');
    final raw = (await SharedPreferences.getInstance())
        .getString(AuthSessionCache.key)!;
    expect(raw, isNot(contains('test#password')));
    expect(raw, isNot(contains('refresh_token')));
    expect(jsonDecode(raw)['token'], 'test-token');
  });

  test('rejected unknown accounts cannot create a staff session', () async {
    final session = createSession(
        (_) async => response({'message': 'Invalid credentials.'}, 401));
    await expectLater(
        session.signIn('unknown@example.test', 'incorrect'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', 'Incorrect login or password.')));
    expect(session.signedIn, isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.key),
        isFalse);
  });

  test('server role determines privileges even when login looks like admin',
      () async {
    final session =
        createSession((_) async => response(sessionJson(admin: false)));
    await session.signIn('admin@example.test', 'test-password');
    expect(session.isAdmin, isFalse);
    expect(session.employeeId, 'api_emp_12');
    expect(session.user!.modules, ['tasks']);
    final employee = authEmployee(session.user!, session.employeeId);
    expect(employee.name, 'Employee One');
    expect(employee.email, 'staff@example.test');
  });

  test('cached session is revalidated and uses the latest server identity',
      () async {
    SharedPreferences.setMockInitialValues(
        {AuthSessionCache.key: jsonEncode(sessionJson())});
    final session = createSession((request) async {
      expect(request.url.path, '/api/team-operations/me');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return response({
        'user': {...userJson(), 'name': 'Updated Admin'}
      });
    });
    await session.load();
    expect(session.signedIn, isTrue);
    expect(session.user!.name, 'Updated Admin');
  });

  test('revoked cached tokens are removed', () async {
    SharedPreferences.setMockInitialValues(
        {AuthSessionCache.key: jsonEncode(sessionJson())});
    final session = createSession((_) async => response({}, 401));
    await session.load();
    expect(session.signedIn, isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.key),
        isFalse);
  });

  test('an unexpired cache survives a temporary network outage', () async {
    SharedPreferences.setMockInitialValues(
        {AuthSessionCache.key: jsonEncode(sessionJson())});
    final session =
        createSession((_) async => throw http.ClientException('offline'));
    await session.load();
    expect(session.signedIn, isTrue);
    expect(session.restoreError, isNotNull);
  });

  for (final raw in [
    '{broken-json',
    jsonEncode({'token': 1, 'user': []}),
    jsonEncode(
        sessionJson(expiry: DateTime.now().subtract(const Duration(hours: 1)))),
  ]) {
    test(
        'invalid or expired cache cannot restore auth: ${raw.substring(0, 10)}',
        () async {
      SharedPreferences.setMockInitialValues({AuthSessionCache.key: raw});
      final session =
          createSession((_) async => fail('Invalid cache should not call API'));
      await session.load();
      expect(session.signedIn, isFalse);
      expect(
          (await SharedPreferences.getInstance())
              .containsKey(AuthSessionCache.key),
          isFalse);
    });
  }

  test('legacy demo login is discarded rather than trusted', () async {
    SharedPreferences.setMockInitialValues({
      AuthSessionCache.legacyKey: '{"role":"admin","email":"demo@example.test"}'
    });
    final session =
        createSession((_) async => fail('Demo identity is not an API session'));
    await session.load();
    expect(session.signedIn, isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.legacyKey),
        isFalse);
  });

  test('logout clears cache and revokes the current device token', () async {
    final session = createSession((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return response(sessionJson());
      }
      expect(
          request.url.path, '/api/team-operations/account-security/sign-out');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return response({'message': 'Signed out'});
    });
    await session.signIn('admin@example.test', 'test-password');
    await session.signOut();
    expect(session.signedIn, isFalse);
    expect(session.accessToken, isNull);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.key),
        isFalse);
  });

  test('logout clears local auth even if token revocation is offline',
      () async {
    final session = createSession((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return response(sessionJson());
      }
      throw http.ClientException('offline');
    });
    await session.signIn('admin@example.test', 'test-password');
    await session.signOut();
    expect(session.signedIn, isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.key),
        isFalse);
  });

  test('logout during login cannot restore a late response', () async {
    final pending = Completer<http.Response>();
    final session = createSession((_) => pending.future);
    final login = session.signIn('admin@example.test', 'test-password');
    final rejected = expectLater(login, throwsFormatException);
    await session.signOut();
    pending.complete(response(sessionJson()));
    await rejected;
    expect(session.signedIn, isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(AuthSessionCache.key),
        isFalse);
  });

  test('late rejection of an old token does not sign out a new session',
      () async {
    var loginCount = 0;
    final session = createSession(
        (_) async => response(sessionJson(token: 'token-${++loginCount}')));
    await session.signIn('admin@example.test', 'test-password');
    await session.signIn('admin@example.test', 'test-password');
    await session.invalidate('token-1');
    expect(session.accessToken, 'token-2');
    await session.invalidate('token-2');
    expect(session.signedIn, isFalse);
  });

  test('password change sends confirmation and refreshes first-login flag',
      () async {
    var changed = false;
    final session = createSession((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return response(sessionJson(mustChange: true));
      }
      if (request.url.path.endsWith('/change-password')) {
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(jsonDecode(request.body), {
          'current_password': 'old-test-password',
          'password': 'new-test-password',
          'password_confirmation': 'new-test-password',
        });
        changed = true;
        return response({'message': 'Changed'});
      }
      expect(changed, isTrue);
      return response({'user': userJson()});
    });
    await session.signIn('admin@example.test', 'test-password');
    expect(session.mustChangePassword, isTrue);
    await session.changePassword('old-test-password', 'new-test-password');
    expect(session.mustChangePassword, isFalse);
    expect(session.signedIn, isTrue);
  });

  test('password rejection is shown and does not claim success', () async {
    final session = createSession((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return response(sessionJson(mustChange: true));
      }
      return response({
        'errors': {
          'current_password': ['Current password is incorrect.']
        }
      }, 422);
    });
    await session.signIn('admin@example.test', 'test-password');
    await expectLater(
        session.changePassword('wrong-password', 'new-test-password'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', 'Current password is incorrect.')));
    expect(session.mustChangePassword, isTrue);
  });
}
