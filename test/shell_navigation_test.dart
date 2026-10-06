import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/features/shell/presentation/shell_screen.dart';
import 'package:neonecy_team_app/features/shell/presentation/widgets/curved_bottom_navigation_bar.dart';
import 'package:neonecy_team_app/features/shell/presentation/widgets/nav_tab_item.dart';
import 'package:neonecy_team_app/features/shell/presentation/widgets/quick_create_sheet.dart';

Future<GoRouter> pumpShell(
  WidgetTester tester, {
  double width = 428,
  bool dark = false,
  double textScale = 1,
  double bottomInset = 0,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          for (final path in ['/home', '/leads', '/tasks', '/more'])
            GoRoute(
              path: path,
              builder: (_, __) => Scaffold(body: Center(child: Text(path))),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        extensions: [dark ? const NecColors.dark() : const NecColors.light()],
      ),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(bottom: bottomInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(textDirection: direction, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('tabs change routes and keep the raised icon above their label',
      (tester) async {
    final router = await pumpShell(tester);
    final destinations = [
      ('Home', '/home', CupertinoIcons.house_fill),
      ('Leads', '/leads', CupertinoIcons.person_2_fill),
      ('Tasks', '/tasks', CupertinoIcons.checkmark_square_fill),
      ('More', '/more', CupertinoIcons.ellipsis_circle_fill),
    ];
    for (final destination in destinations) {
      await tester.tap(find.text(destination.$1));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, destination.$2);
      final icon = tester.getCenter(find.byIcon(destination.$3));
      final label = tester.getCenter(find.text(destination.$1));
      expect(icon.dx, closeTo(label.dx, 0.1));
      expect(label.dy - icon.dy, greaterThan(10));
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();
    expect(find.byType(QuickCreateSheet), findsOneWidget);
    expect(find.text('Add Lead'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/more');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickCreateSheet), findsNothing);
  });

  testWidgets('narrow dark layout supports scaled text, safe area, and RTL',
      (tester) async {
    await pumpShell(
      tester,
      width: 320,
      dark: true,
      textScale: 2,
      bottomInset: 34,
      direction: TextDirection.rtl,
    );
    final bar = tester.getRect(find.byType(CurvedBottomNavigationBar));
    final homeIcon = tester.getCenter(find.byIcon(CupertinoIcons.house_fill));
    final homeLabel = tester.getRect(find.text('Home'));
    expect(homeIcon.dx, closeTo(homeLabel.center.dx, 0.1));
    expect(homeIcon.dx, greaterThan(160));
    expect(homeLabel.bottom, lessThanOrEqualTo(bar.bottom - 34));
    expect(tester.getSize(find.byType(CurvedBottomNavigationBar)).height, 94);
    expect(tester.widget<Icon>(find.byIcon(CupertinoIcons.house_fill)).color,
        const Color(0xFF3880FF));
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(NavTabItem).first),
      matchesSemantics(
          label: 'Home',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true),
    );
    semantics.dispose();
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('/tasks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
