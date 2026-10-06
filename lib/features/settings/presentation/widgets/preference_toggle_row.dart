import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class PreferenceToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? note;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  const PreferenceToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.note,
    required this.value,
    this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                        height: 1.3,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: value,
                activeTrackColor: AppColors.success,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: nec.separator.withValues(alpha: 0.3),
            indent: 16,
          ),
      ],
    );
  }
}
