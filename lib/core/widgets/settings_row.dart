import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsRow extends StatelessWidget {
  final Widget? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showSeparator;

  const SettingsRow({
    super.key,
    this.icon,
    this.iconBg,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg ?? const Color(0x26787880),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(
                        color: iconColor ?? nec.textSecondary,
                        size: 16,
                      ),
                      child: icon!,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, color: nec.textPrimary),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: nec.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: nec.textTertiary,
                      size: 20,
                    ),
              ],
            ),
          ),
          if (showSeparator)
            Divider(
              indent: icon != null ? 60 : 16,
              endIndent: 0,
              height: 0.5,
              color: nec.separator,
            ),
        ],
      ),
    );
  }
}

class GroupedSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const GroupedSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: nec.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
