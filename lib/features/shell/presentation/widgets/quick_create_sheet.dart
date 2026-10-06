import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../more/presentation/widgets/add_follow_up_sheet.dart';
import '../../../more/presentation/widgets/schedule_visit_sheet.dart';

class QuickCreateSheet extends StatelessWidget {
  const QuickCreateSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final items = [
      (
        CupertinoIcons.person_add,
        AppColors.brandLight,
        'Add Lead',
        'Create a new lead'
      ),
      (
        CupertinoIcons.person_badge_plus,
        AppColors.leadContacted,
        'Add Employee',
        'Onboard a new team member'
      ),
      if (DemoSession.instance.isAdmin)
        (
          CupertinoIcons.money_dollar_circle,
          const Color(0xFFFF9500),
          'Log Expense',
          'Record company expense'
        ),
      (
        CupertinoIcons.reply,
        AppColors.warning,
        'Add Follow-up',
        'Schedule a follow-up'
      ),
      (
        CupertinoIcons.house_fill,
        AppColors.leadVisit,
        'Schedule Visit',
        'Plan a site visit'
      ),
      (
        CupertinoIcons.checkmark_rectangle,
        AppColors.brandLight,
        'Create Task',
        'Add a new task'
      ),
      (
        CupertinoIcons.exclamationmark_octagon,
        AppColors.error,
        'Report Issue',
        'Log a new issue'
      ),
    ];

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: nec.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'New',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: nec.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 0.5, color: nec.separator.withValues(alpha: 0.3)),
            ...items
                .where((action) =>
                    StaffAccessStore.instance.canOpen(switch (action.$3) {
                      'Add Lead' => '/add-lead',
                      'Add Employee' => '/add-employee',
                      'Log Expense' => '/expenses',
                      'Add Follow-up' => '/follow-ups',
                      'Schedule Visit' => '/visits',
                      'Create Task' => '/create-task',
                      _ => '/report-issue',
                    }) &&
                    switch (action.$3) {
                      'Add Follow-up' => StaffAccessStore.instance
                          .allows(StaffPermission.scheduleFollowUp),
                      'Schedule Visit' => StaffAccessStore.instance
                          .allows(StaffPermission.scheduleVisit),
                      _ => true,
                    })
                .map(
                  (action) => ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: action.$2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(action.$1, color: action.$2, size: 20),
                    ),
                    title: Text(
                      action.$3,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: nec.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      action.$4,
                      style: TextStyle(fontSize: 13, color: nec.textTertiary),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: nec.textTertiary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (action.$3 == 'Add Lead') {
                        context.push('/add-lead');
                      } else if (action.$3 == 'Add Employee') {
                        context.push('/add-employee');
                      } else if (action.$3 == 'Log Expense') {
                        context.push('/expenses');
                      } else if (action.$3 == 'Add Follow-up') {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const AddFollowUpSheet(),
                        );
                      } else if (action.$3 == 'Schedule Visit') {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const ScheduleVisitSheet(),
                        );
                      } else if (action.$3 == 'Create Task') {
                        context.push('/create-task');
                      } else if (action.$3 == 'Report Issue') {
                        context.push('/issues');
                      }
                    },
                  ),
                ),
            ListTile(
              title: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: nec.textSecondary,
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
