import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileActivityTab extends StatelessWidget {
  const ProfileActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final activities = [
      {
        'action': 'completed follow-up with',
        'target': 'Blue Wave Resort',
        'time': '2h ago',
        'dotColor': AppColors.warning,
      },
      {
        'action': 'moved lead to Negotiation',
        'target': 'Ocean Paradise Hotel',
        'time': '4h ago',
        'dotColor': AppColors.brandLight,
      },
      {
        'action': 'completed visit at',
        'target': 'Sea Pearl Resort',
        'time': 'Yesterday',
        'dotColor': AppColors.leadVisit,
      },
      {
        'action': 'reported issue',
        'target': 'Mobile app crash on login',
        'time': 'Yesterday',
        'dotColor': AppColors.error,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/activity'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View Full Activity Log',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.brand,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: nec.brand,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(activities.length, (index) {
                final item = activities[index];
                final isLast = index == activities.length - 1;
                final dotColor = item['dotColor'] as Color;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'You ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${item['action']} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: nec.textSecondary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: item['target'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: nec.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['time'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nec.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.3),
                        indent: 36,
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
