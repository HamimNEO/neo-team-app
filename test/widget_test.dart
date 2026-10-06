import 'package:flutter_test/flutter_test.dart';
import 'package:neonecy_team_app/core/theme/theme_provider.dart';
import 'package:neonecy_team_app/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('app displays its splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const NecTeamApp(),
      ),
    );

    expect(find.text('NEC TEAM'), findsOneWidget);
    expect(find.text('BY NEONECY'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
