import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';

class GlassCircleButton extends StatelessWidget {
  final double size;
  final VoidCallback onPressed;
  final Widget child;

  const GlassCircleButton({
    super.key,
    this.size = 44,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.45),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeThemeToggle extends StatelessWidget {
  const HomeThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.mode == AppThemeMode.dark ||
        (themeProvider.mode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Tooltip(
      message: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      child: GlassCircleButton(
        onPressed: () => themeProvider.setMode(
          isDark ? AppThemeMode.light : AppThemeMode.dark,
        ),
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
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
            color: isDark ? const Color(0xFFC782FE) : const Color(0xFFFFA726),
            size: 22,
          ),
        ),
      ),
    );
  }
}
