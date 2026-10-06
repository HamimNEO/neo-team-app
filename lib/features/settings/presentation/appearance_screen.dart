import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import 'widgets/appearance_theme_tile.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final themeProvider = context.watch<ThemeProvider>();

    final options = [
      (
        AppThemeMode.system,
        'System',
        'Matches your device setting',
        '⚙️',
      ),
      (
        AppThemeMode.light,
        'Light',
        'Always use light appearance',
        '☀️',
      ),
      (
        AppThemeMode.dark,
        'Dark',
        'Always use dark appearance',
        '🌙',
      ),
    ];

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: nec.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: nec.textPrimary,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Choose how NEC TEAM looks on your device.',
              style: TextStyle(
                fontSize: 13,
                color: nec.textTertiary,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: options.asMap().entries.map((entry) {
                  final option = entry.value;
                  final isLast = entry.key == options.length - 1;
                  final isSelected = themeProvider.mode == option.$1;

                  return AppearanceThemeTile(
                    mode: option.$1,
                    title: option.$2,
                    description: option.$3,
                    iconEmoji: option.$4,
                    isSelected: isSelected,
                    isLast: isLast,
                    onTap: () =>
                        context.read<ThemeProvider>().setMode(option.$1),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'System follows your device setting. Light and Dark override it.',
              style: TextStyle(
                fontSize: 12,
                color: nec.textTertiary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
