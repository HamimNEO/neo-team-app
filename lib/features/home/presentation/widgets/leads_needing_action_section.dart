import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class LeadsNeedingActionSection extends StatelessWidget {
  const LeadsNeedingActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final items = [
      {
        'id': 'fu_001',
        'title': 'Sea Pearl Resort',
        'subtitle': 'Follow-up call · Tomorrow, 11:30 AM',
        'badgeText': 'Follow-up',
        'badgeColor': AppColors.warning,
        'route': '/follow-up-details/fu_001',
      },
      {
        'id': 'fu_002',
        'title': 'Blue Wave Resort',
        'subtitle': 'Follow-up · Today, 4:00 PM',
        'badgeText': 'Interested',
        'badgeColor': AppColors.success,
        'route': '/follow-up-details/fu_002',
      },
    ];

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.map((item) {
          final badgeColor = item['badgeColor'] as Color;
          return InkWell(
            onTap: () => context.push(item['route'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_2,
                      color: AppColors.brandLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['badgeText'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
