import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/core/storage/preferences_store.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/settings/data/datasources/profile_api.dart';
import 'package:neonecy_team_app/features/settings/data/datasources/profile_cache.dart';
import 'package:neonecy_team_app/features/settings/data/profile_store.dart';
import 'package:neonecy_team_app/features/settings/data/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_fixture.dart';
import '../../support/profile_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(signInWidgetAdmin);
  tearDown(() => AuthSession.instance.signOut());

  ProfileStore createStore(
      Future<http.Response> Function(http.Request) handler) {
    final client = ApiClient(
        baseUrl: () => 'https://example.test/api',
        client: MockClient(handler),
        onUnauthorized: AuthSession.instance.invalidate);
    final store = ProfileStore(
        session: AuthSession.instance,
        repository: ProfileRepository(
          api: ProfileApi(client),
          cache: const ProfileCache(PreferencesStore()),
        ));
    addTearDown(store.dispose);
    addTearDown(client.close);
    return store;
  }

  test('profile fetch uses bearer auth and caches only the returned identity',
      () async {
    final store = createStore((request) async {
      expect(request.url.path, '/api/team-operations/profile');
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer widget-test-token');
      return http.Response(jsonEncode(profileJson()), 200);
    });
    await store.load();
    expect(store.profile!.organization, 'Backend Organization');
    expect(store.profile!.roleLabel, 'Super Admin');
    expect(store.profile!.statusLabel, 'Active');
    expect(store.profile!.phone, isNull);
    expect(store.profile!.department, isNull);
    expect(store.loadError, isNull);
    final cached = (await SharedPreferences.getInstance())
        .getString(ProfileCache.keyFor('usr_test'));
    expect(jsonDecode(cached!)['id'], 'usr_test');
  });

  test('a profile visit refreshes cached backend data', () async {
    var calls = 0;
    final store = createStore((_) async =>
        http.Response(jsonEncode(profileJson(name: 'Admin ${++calls}')), 200));
    await store.load();
    await store.load();
    expect(store.profile!.name, 'Admin 2');
  });

  test('an offline visit can display its own previously cached profile',
      () async {
    await (await SharedPreferences.getInstance()).setString(
        ProfileCache.keyFor('usr_test'), jsonEncode(profileJson()['profile']));
    final store =
        createStore((_) async => throw http.ClientException('offline'));
    await store.load();
    expect(store.profile!.organization, 'Backend Organization');
    expect(store.loadError, isNotNull);
  });

  test('a different backend identity is neither displayed nor cached',
      () async {
    final store = createStore((_) async =>
        http.Response(jsonEncode(profileJson(id: 'other-account')), 200));
    await store.load();
    expect(store.profile, isNull);
    expect(store.loadError, isNotNull);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(ProfileCache.keyFor('other-account')),
        isFalse);
  });

  test('a late profile response cannot display after sign-out', () async {
    final pending = Completer<http.Response>();
    final requested = Completer<void>();
    final store = createStore((_) {
      requested.complete();
      return pending.future;
    });
    final loading = store.load();
    await requested.future;
    await AuthSession.instance.signOut();
    pending.complete(http.Response(jsonEncode(profileJson()), 200));
    await loading;
    expect(store.profile, isNull);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(ProfileCache.keyFor('usr_test')),
        isFalse);
  });

  test('a rejected profile token clears auth and the displayed profile',
      () async {
    final store = createStore((_) async => http.Response('{}', 401));
    await store.load();
    expect(AuthSession.instance.signedIn, isFalse);
    expect(store.profile, isNull);
  });
}
