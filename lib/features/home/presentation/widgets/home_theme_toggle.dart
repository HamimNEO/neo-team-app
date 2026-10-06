import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeThemeToggle extends StatelessWidget {
  const HomeThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.mode == AppThemeMode.dark ||
        (themeProvider.mode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Tooltip(
      message: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      child: SizedBox.square(
        dimension: 44,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: nec.surface,
          borderRadius: BorderRadius.circular(22),
          onPressed: () => themeProvider.setMode(
            isDark ? AppThemeMode.light : AppThemeMode.dark,
          ),
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 450),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: Tween<double>(begin: -0.125, end: 0).animate(animation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.75, end: 1).animate(animation),
                  child: child,
                ),
              ),
            ),
            child: Icon(
              isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
              key: ValueKey(isDark),
              color: isDark ? nec.brand : const Color(0xFFFFA726),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
