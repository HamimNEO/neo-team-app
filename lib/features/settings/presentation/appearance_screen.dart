import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import 'widgets/appearance_theme_tile.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeModes = [
      (
        style: AppThemeStyle.defaultMode,
        title: 'Default',
        description: 'Classic clean NEONECY interface',
        iconEmoji: '🎨',
        primaryColor: const Color(0xFF0071E3),
        bgColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        tagText: 'STANDARD',
      ),
      (
        style: AppThemeStyle.bluish,
        title: 'Bluish',
        description: 'Modern cool blue tone with crisp ocean contrast',
        iconEmoji: '🌊',
        primaryColor: const Color(0xFF0284C7),
        bgColor: isDark ? const Color(0xFF111E30) : const Color(0xFFEDF4FA),
        tagText: 'COOL BLUE',
      ),
      (
        style: AppThemeStyle.eyeProtect,
        title: 'Eyes Protect',
        description: 'Warm yellow amber tint to reduce eye strain & fatigue',
        iconEmoji: '👁️',
        primaryColor: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF24201A) : const Color(0xFFFAF6EB),
        tagText: 'EYE CARE',
      ),
    ];

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Text(
                'THEME COLOR MODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textTertiary,
                  letterSpacing: 0.5,
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
                  children: themeModes.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == themeModes.length - 1;
                    final isSelected = themeProvider.style == item.style;

                    return AppearanceThemeTile(
                      title: item.title,
                      description: item.description,
                      iconEmoji: item.iconEmoji,
                      primaryColor: item.primaryColor,
                      bgColor: item.bgColor,
                      tagText: item.tagText,
                      isSelected: isSelected,
                      isLast: isLast,
                      onTap: () {
                        AppHaptics.selectionClick();
                        context.read<ThemeProvider>().setStyle(item.style);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Eyes Protect mode filters blue light and uses warm amber tones to protect eyes during long work sessions.',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                  height: 1.45,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Text(
                'DISPLAY THEME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isDark ? '🌙' : '☀️',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isDark
                        ? 'Dark appearance active'
                        : 'Light appearance active (Default)',
                    style: TextStyle(fontSize: 12, color: nec.textTertiary),
                  ),
                  trailing: CupertinoSwitch(
                    value: isDark,
                    activeTrackColor: nec.brand,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      context.read<ThemeProvider>().toggleDarkMode(val);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Light theme is set as the automatic default. Toggle switch to quickly switch between Light and Dark mode.',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
