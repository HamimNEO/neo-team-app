import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/demo_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'nec_toast.dart';

Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out of NEC TEAM?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Sign Out',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'SignOutLoading',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogCtx, anim1, anim2) {
      final nec = Theme.of(dialogCtx).extension<NecColors>()!;
      final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 290,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                        color: nec.brand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Signing Out...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clearing local cache & securing your session...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: nec.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  try {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('theme_mode');
    await prefs.clear();
    if (themeMode != null) {
      await prefs.setString('theme_mode', themeMode);
    }

    await DemoSession.instance.signOut();
    await Future.delayed(const Duration(milliseconds: 700));
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/login');
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      NecToast.show(
        context,
        message: 'Unable to sign out cleanly. Redirecting to login.',
        type: NecToastType.error,
      );
      context.go('/login');
    }
  }
}
