import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neonecy_team_app/core/constants/app_constants.dart';
import 'package:neonecy_team_app/core/router/app_router.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:neonecy_team_app/core/widgets/nec_avatar.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/home/presentation/widgets/home_greeting_bar.dart';
import 'package:neonecy_team_app/features/settings/data/profile_store.dart';
import 'package:neonecy_team_app/features/settings/domain/models/account_profile.dart';
import 'package:neonecy_team_app/features/settings/presentation/profile_screen.dart';
import 'package:neonecy_team_app/features/settings/presentation/widgets/admin_profile_tabs.dart';
import 'package:neonecy_team_app/features/settings/presentation/widgets/profile_header.dart';
import 'package:neonecy_team_app/features/team/data/employee_store.dart';
import 'package:neonecy_team_app/features/attendance/data/attendance_store.dart';
import 'package:neonecy_team_app/features/leads/data/lead_store.dart';
import 'package:neonecy_team_app/features/meals/data/meal_store.dart';

import '../../support/auth_fixture.dart';
import '../../support/profile_fixture.dart';

ThemeData get testTheme => ThemeData(extensions: const [NecColors.light()]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await signInWidgetAdmin();
    await Future.wait([
      EmployeeStore.instance.load(),
      AttendanceStore.instance.load(),
      LeadStore.instance.load(),
      MealStore.instance.load(),
    ]);
    await withWidgetApiClient(() => ProfileStore.instance.load());
  });
  tearDown(() => AuthSession.instance.signOut());

  testWidgets(
      'overview hides missing API fields and local organization defaults',
      (tester) async {
    final profile = AccountProfile.fromJson(
        profileJson()['profile'] as Map<String, dynamic>);
    await tester.pumpWidget(MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: SingleChildScrollView(
              child: AdminProfileOverviewTab(profile: profile)),
        )));
    expect(find.text('Backend Organization'), findsOneWidget);
    expect(find.text('admin@example.test'), findsOneWidget);
    expect(find.text('SUPER-ADMIN'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);
    expect(find.text('Super Admin'), findsNWidgets(2));
    for (final hidden in [
      'Phone',
      'Address',
      'Department',
      'Primary Email',
      'Timezone',
      'Not provided',
      'CONTACT',
      'Administrator',
      'Full administration'
    ]) {
      expect(find.text(hidden), findsNothing);
    }
  });

  testWidgets(
      'profile hides all admin edit controls and uses the requested image',
      (tester) async {
    final router = GoRouter(initialLocation: '/profile', routes: [
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/more', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/messages', builder: (_, __) => const Scaffold()),
    ]);
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(428, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp.router(theme: testTheme, routerConfig: router));
    await tester.pump();
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.byIcon(CupertinoIcons.square_pencil), findsNothing);
    expect(find.byIcon(CupertinoIcons.pencil), findsNothing);
    expect(tester.widget<NecAvatar>(find.byType(NecAvatar).first).assetPath,
        AppConstants.superAdminAvatarAsset);
    expect(find.text('Backend Organization'), findsWidgets);
    await tester.ensureVisible(find.text('More'));
    await tester.tap(find.text('More'));
    await tester.pump();
    expect(find.text('Edit Profile'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('staff profile header displays avatar and info', (tester) async {
    final employee = EmployeeStore.instance.staffEmployees.first;
    await tester.pumpWidget(MaterialApp(
        theme: testTheme,
        home: Scaffold(
          body: ProfileHeader(employee: employee),
        )));
    expect(find.text(employee.name), findsOneWidget);
    expect(tester.widget<NecAvatar>(find.byType(NecAvatar)).assetPath, isNull);
  });

  testWidgets('home avatar uses Super Admin image', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
            theme: testTheme,
            home: const Scaffold(
              body: HomeGreetingBar(
                  userName: 'unused',
                  userInitials: 'unused',
                  dateString: 'Today'),
            ))));
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    final assetImage = provider is ResizeImage
        ? provider.imageProvider as AssetImage
        : provider as AssetImage;
    expect(assetImage.assetName, AppConstants.superAdminAvatarAsset);
  });

  testWidgets('direct edit-profile navigation resolves to read-only profile',
      (tester) async {
    appRouter.go('/edit-profile');
    await tester.pumpWidget(
        MaterialApp.router(theme: testTheme, routerConfig: appRouter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(appRouter.routeInformationProvider.value.uri.path, '/profile');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('local store cannot save Super Admin personal details', () async {
    await expectLater(
        EmployeeStore.instance.save(EmployeeStore.instance.currentEmployee),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            'Super Admin profiles are read-only.')));
  });
}
