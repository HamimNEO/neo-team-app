import 'employee_offboarding_sheet.dart';
import '../../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/employee.dart';
import '../../data/employee_store.dart';
import '../../services/employee_report_pdf_service.dart';

class EmployeeActionSheet extends StatelessWidget {
  final Employee employee;

  const EmployeeActionSheet({
    super.key,
    required this.employee,
  });

  Future<void> _confirmDeactivate(BuildContext context) async {
    final isSuspended =
        employee.status == 'Suspended' || employee.status != 'Active';
    if (!isSuspended) {
      Navigator.pop(context);
      await EmployeeOffboardingSheet.show(context, employee);
      return;
    }
    final action = isSuspended ? 'Reactivate' : 'Suspend Account';
    final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
                title: Text('$action ${employee.name}?'),
                content: Text(isSuspended
                    ? 'This will restore access for ${employee.name}.'
                    : 'This will immediately revoke access and prevent ${employee.name} from signing in.'),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  CupertinoDialogAction(
                      isDestructiveAction: !isSuspended,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(action)),
                ]));
    if (confirmed != true || !context.mounted) return;
    try {
      await EmployeeStore.instance.suspendEmployee(employee, !isSuspended);
      if (!context.mounted) return;
      NecToast.show(context,
          message: isSuspended
              ? 'Employee account reactivated'
              : 'Employee account suspended');
      Navigator.pop(context);
    } catch (exception) {
      if (context.mounted) {
        NecToast.show(context,
            message: EmployeeStore.messageFor(exception),
            type: NecToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final isSuspended =
        employee.status == 'Suspended' || employee.status != 'Active';

    final actions = [
      {
        'label': 'View Attendance',
        'color': nec.brand,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/attendance/employee/${employee.id}');
        },
      },
      {
        'label': 'Download employee details report',
        'color': nec.brand,
        'onTap': () {
          Navigator.pop(context);
          EmployeeReportPdfService.downloadAndOpenReport(context, employee);
        },
      },
      {
        'label': 'Edit Employee',
        'color': nec.brand,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/edit-employee/${employee.id}');
        },
      },
      {
        'label': 'Change Department',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/edit-employee/${employee.id}');
        },
      },
      {
        'label': 'Change Team',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/edit-employee/${employee.id}');
        },
      },
      {
        'label': 'Change Reporting Manager',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/edit-employee/${employee.id}');
        },
      },
      {
        'label': 'Change Role',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          context.pushAppRoute('/edit-employee/${employee.id}');
        },
      },
      {
        'label': isSuspended ? 'Reactivate Account' : 'Suspend Account',
        'color': isSuspended ? nec.brand : AppColors.error,
        'onTap': () => _confirmDeactivate(context),
      },
    ];

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
            const SizedBox(height: 12),
            Column(
              children: List.generate(actions.length, (index) {
                final action = actions[index];
                final isLast = index == actions.length - 1;
                final color = action['color'] as Color;

                return Column(
                  children: [
                    InkWell(
                      onTap: action['onTap'] as VoidCallback,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          action['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
