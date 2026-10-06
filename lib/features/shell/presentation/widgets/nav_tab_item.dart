import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NavTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isAction;

  const NavTabItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const actionAccent = Color(0xFF6355F6);
    const activeColor = Color(0xFF3880FF);
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E95A5);

    if (isAction) {
      return Expanded(
        child: Semantics(
          label: label,
          button: true,
          onTap: onTap,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: actionAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: actionAccent.withValues(
                          alpha: isDark ? 0.60 : 0.45,
                        ),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final color = active ? activeColor : inactiveColor;

    return Expanded(
      child: Semantics(
        label: badgeCount != null && badgeCount! > 0
            ? '$label, $badgeCount pending'
            : label,
        button: true,
        onTap: onTap,
        selected: active,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NavTabIcon(
                icon: active ? activeIcon : icon,
                color: color,
                badgeCount: badgeCount,
                size: 17,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: active ? 12 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: active ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: activeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavTabIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? badgeCount;
  final double size;

  const NavTabIcon({
    super.key,
    required this.icon,
    required this.color,
    this.badgeCount,
    this.size = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: size),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -2,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              child: Text(
                badgeCount! > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
      ],
    );
  }
}
