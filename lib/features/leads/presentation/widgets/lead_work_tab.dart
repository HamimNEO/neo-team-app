import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class LeadWorkTab extends StatelessWidget {
  const LeadWorkTab({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'FOLLOW-UP'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Today · 4:00 PM',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Discuss product demo',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned: Shahina Akter',
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            NecToast.show(
                              context,
                              message: 'Follow-up completed',
                              type: NecToastType.success,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.success.withValues(alpha: 0.15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            NecToast.show(
                              context,
                              message: 'Reschedule coming soon',
                              type: NecToastType.info,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nec.bg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reschedule',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'VISIT'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tomorrow · 11:00 AM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.leadVisit.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SCHEDULED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.leadVisit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Blue Wave Resort, Cox\'s Bazar',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Product demo',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Assigned: Shahina Akter',
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () =>
                              context.push('/visit-details/visit_001'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Journey',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            NecToast.show(
                              context,
                              message: 'Reschedule coming soon',
                              type: NecToastType.info,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nec.bg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reschedule',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'TASKS'),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push('/create-task'),
                child: Text(
                  '+ Task',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nec.brand,
                  ),
                ),
              ),
            ],
          ),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nec.textTertiary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  title: Text(
                    'Prepare demo account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Today · Shahina Akter',
                    style: TextStyle(fontSize: 12, color: nec.textTertiary),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'High',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  onTap: () => context.push('/tasks/task_1'),
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 52,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nec.textTertiary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  title: Text(
                    'Send proposal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Tomorrow · Yeapas',
                    style: TextStyle(fontSize: 12, color: nec.textTertiary),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Normal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandLight,
                      ),
                    ),
                  ),
                  onTap: () => context.push('/tasks/task_2'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
