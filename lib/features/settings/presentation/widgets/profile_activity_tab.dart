import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileActivityTab extends StatelessWidget {
  const ProfileActivityTab({super.key, this.activities = const []});

  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    String timeLabel(Object? value) {
      final date = DateTime.tryParse(value?.toString() ?? '');
      return date == null ? '' : DateFormat('d MMM yyyy · h:mm a').format(date);
    }

    final records = activities
        .map((event) => {
              'description': event['description']?.toString() ??
                  event['event']?.toString() ??
                  '',
              'time': timeLabel(event['occurred_at']),
              'dotColor': AppColors.brandLight,
            })
        .toList();

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
                    Expanded(
                      child: Text(
                        'View Full Activity Log',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
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
              children: records.isEmpty
                  ? [
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No recent activity',
                              style: TextStyle(color: nec.textSecondary)))
                    ]
                  : List.generate(records.length, (index) {
                      final item = records[index];
                      final isLast = index == records.length - 1;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['description'] as String,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: nec.textPrimary,
                                            height: 1.4),
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
