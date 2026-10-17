import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/auth/presentation/login_screen.dart';

import '../../support/auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await signInWidgetAdmin();
    await AuthSession.instance.signOut();
  });
  tearDown(() => AuthSession.instance.signOut());

  testWidgets(
      'existing login form displays rejection then navigates on success',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(428, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Authenticated home'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: ThemeData(extensions: const [NecColors.light()]),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'admin@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'incorrect');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect login or password.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(AuthSession.instance.signedIn, isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'test-password');
    await tester.runAsync(() async {
      await tester.tap(find.text('Sign In'));
      // Shared Preferences futures were initialized in setUp's real zone.
      // Let those writes finish before settling the fake widget clock.
      for (var attempt = 0;
          attempt < 100 && !AuthSession.instance.signedIn;
          attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Authenticated home'), findsOneWidget);
    expect(AuthSession.instance.isAdmin, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
