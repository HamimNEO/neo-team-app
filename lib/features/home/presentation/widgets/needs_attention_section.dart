import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class NeedsAttentionSection extends StatelessWidget {
  final bool staff;
  const NeedsAttentionSection({super.key, this.staff = false});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final items = [
      {
        'id': 'fu_001',
        'title': 'Sea Pearl Resort',
        'subtitle': 'Follow-up overdue · 20h',
        'isOverdue': true,
        'icon': CupertinoIcons.arrow_turn_down_left,
        'route': '/follow-up-details/fu_001',
      },
      {
        'id': 'fu_002',
        'title': 'Ocean Nest Hotel',
        'subtitle': 'Follow-up overdue · 3h',
        'isOverdue': true,
        'icon': CupertinoIcons.arrow_turn_down_left,
        'route': '/follow-up-details/fu_002',
      },
      {
        'id': 'lead_3',
        'title': 'Ocean Paradise Hotel',
        'subtitle': 'Unassigned · New Lead',
        'isOverdue': false,
        'icon': CupertinoIcons.person_2,
        'route': '/leads/lead_3',
      },
      {
        'id': 'lead_4',
        'title': 'Coral Reef Resort',
        'subtitle': 'Unassigned · New Lead',
        'isOverdue': false,
        'icon': CupertinoIcons.person_2,
        'route': '/leads/lead_4',
      },
    ].where((item) => !staff || item['id'].toString().startsWith('fu_')).toList();

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.map((item) {
          final isOverdue = item['isOverdue'] as bool;
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
                      color: isOverdue
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color:
                          isOverdue ? AppColors.warning : AppColors.brandLight,
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
                            color: isOverdue
                                ? AppColors.warning
                                : nec.textTertiary,
                            fontWeight:
                                isOverdue ? FontWeight.w500 : FontWeight.normal,
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
        }).toList(),
      ),
    );
  }
}
