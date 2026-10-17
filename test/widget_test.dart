import 'package:flutter_test/flutter_test.dart';
import 'package:neonecy_team_app/core/theme/theme_provider.dart';
import 'package:neonecy_team_app/main.dart';
import 'package:provider/provider.dart';
import 'package:neonecy_team_app/features/splash/presentation/splash_screen.dart';
import 'package:neonecy_team_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('app displays its splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const NecTeamApp(),
      ),
    );

    final splash = find.byType(SplashScreen);
    expect(splash, findsOneWidget);
    expect(find.descendant(of: splash, matching: find.text('NEC TEAM')),
        findsOneWidget);
    expect(find.descendant(of: splash, matching: find.text('BY NEONECY')),
        findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
