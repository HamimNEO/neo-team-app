import 'package:flutter/material.dart';
import '../../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'complete_follow_up_sheet.dart';
import 'reschedule_follow_up_sheet.dart';

class FollowUpOptionsSheet extends StatelessWidget {
  final String leadId;
  final String leadName;
  final String currentSchedule;

  const FollowUpOptionsSheet({
    super.key,
    required this.leadId,
    required this.leadName,
    required this.currentSchedule,
  });

  void _openCompleteSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompleteFollowUpSheet(leadName: leadName),
    );
  }

  void _openRescheduleSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RescheduleFollowUpSheet(
        currentSchedule: currentSchedule,
        leadName: leadName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: nec.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (StaffAccessStore.instance.allows(StaffPermission.leads))
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/leads/$leadId');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Open Lead',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.brand,
                    ),
                  ),
                ),
              ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            InkWell(
              onTap: () => _openCompleteSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Complete Follow-up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            InkWell(
              onTap: () => _openRescheduleSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Reschedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                NecToast.show(
                  context,
                  message: 'Follow-up cancelled',
                  type: NecToastType.info,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Cancel Follow-up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
