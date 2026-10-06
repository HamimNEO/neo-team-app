import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NecButtonVariant { primary, secondary, tertiary, destructive, ghost }

enum NecButtonSize { sm, md, lg }

class NecButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NecButtonVariant variant;
  final NecButtonSize size;
  final bool fullWidth, loading;
  final Widget? icon;

  const NecButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.variant = NecButtonVariant.primary,
      this.size = NecButtonSize.md,
      this.fullWidth = false,
      this.loading = false,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final h = {
      NecButtonSize.sm: 36.0,
      NecButtonSize.md: 50.0,
      NecButtonSize.lg: 56.0
    };
    final fs = {
      NecButtonSize.sm: 15.0,
      NecButtonSize.md: 17.0,
      NecButtonSize.lg: 17.0
    };
    final px = {
      NecButtonSize.sm: 16.0,
      NecButtonSize.md: 20.0,
      NecButtonSize.lg: 24.0
    };
    final dis = onPressed == null || loading;
    Color bg, fg;
    switch (variant) {
      case NecButtonVariant.primary:
        bg = dis
            ? AppColors.brandLight.withValues(alpha: 0.4)
            : AppColors.brandLight;
        fg = Colors.white;
      case NecButtonVariant.secondary:
        bg = AppColors.brandSubtleLight;
        fg = AppColors.brandLight;
      case NecButtonVariant.tertiary:
        bg = const Color(0x1E787880);
        fg = Theme.of(context).colorScheme.onSurface;
      case NecButtonVariant.destructive:
        bg = dis ? AppColors.error.withValues(alpha: 0.3) : AppColors.error;
        fg = Colors.white;
      case NecButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.brandLight;
    }
    return SizedBox(
        height: h[size],
        width: fullWidth ? double.infinity : null,
        child: TextButton(
            onPressed: dis ? null : onPressed,
            style: TextButton.styleFrom(
                backgroundColor: bg,
                padding: EdgeInsets.symmetric(horizontal: px[size]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(fg)))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(label,
                        style: TextStyle(
                            fontSize: fs[size],
                            fontWeight: FontWeight.w600,
                            color: fg)),
                  ])));
  }
}
