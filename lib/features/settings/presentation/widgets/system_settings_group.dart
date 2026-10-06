import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SystemSettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SystemSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(height: 1, thickness: 0.5, color: nec.separator),
          ],
        ],
      ),
    );
  }
}

class SystemSettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final bool locked;
  final bool? switchValue;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const SystemSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.locked = false,
    this.switchValue,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: locked ? nec.textSecondary : nec.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: locked
                          ? nec.textTertiary.withValues(alpha: 0.7)
                          : nec.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.38),
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: nec.textTertiary),
              ),
            ),
          ],
          if (switchValue != null) ...[
            const SizedBox(width: 8),
            Semantics(
              label: title,
              child: Transform.scale(
                scale: 0.85,
                child: CupertinoSwitch(
                  value: switchValue!,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.success,
                ),
              ),
            ),
          ] else if (locked) ...[
            const SizedBox(width: 16),
            Icon(CupertinoIcons.lock, size: 18, color: nec.textTertiary),
          ] else if (onTap != null) ...[
            const SizedBox(width: 10),
            Icon(CupertinoIcons.chevron_right,
                size: 13, color: nec.textTertiary),
          ],
        ],
      ),
    );

    return onTap == null || locked
        ? content
        : CupertinoButton(
            padding: EdgeInsets.zero, onPressed: onTap, child: content);
  }
}
