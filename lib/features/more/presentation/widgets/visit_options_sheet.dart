import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class VisitOptionsSheet extends StatelessWidget {
  final String leadId;
  final String visitId;

  const VisitOptionsSheet({
    super.key,
    required this.leadId,
    required this.visitId,
  });

  void _confirmCancel(BuildContext context) {
    Navigator.pop(context);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cancel Visit?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'This scheduled visit will be cancelled.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              NecToast.show(
                context,
                message: 'Visit cancelled',
                type: NecToastType.info,
              );
            },
            child: const Text('Cancel Visit'),
          ),
        ],
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
              onTap: () {
                Navigator.pop(context);
                NecToast.show(
                  context,
                  message: 'Reschedule coming soon',
                  type: NecToastType.info,
                );
              },
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
              onTap: () => _confirmCancel(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Cancel Visit',
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
