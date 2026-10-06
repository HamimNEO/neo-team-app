import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActivityListItem extends StatelessWidget {
  final String user;
  final String action;
  final String entity;
  final String time;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const ActivityListItem({
    super.key,
    required this.user,
    required this.action,
    required this.entity,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$user ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                        fontFamily: 'Inter',
                      ),
                      children: [
                        TextSpan(
                          text: '$action ',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: nec.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: entity,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: nec.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
