import '../../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/employee.dart';

class EmployeeActionSheet extends StatelessWidget {
  final Employee employee;

  const EmployeeActionSheet({
    super.key,
    required this.employee,
  });

  void _confirmDeactivate(BuildContext context) {
    Navigator.pop(context);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Deactivate Employee?'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            '${employee.name} will lose access to the app. All historical records will be preserved.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              NecToast.show(
                context,
                message: '${employee.name} deactivated successfully',
                type: NecToastType.success,
              );
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
          NecToast.show(
            context,
            message: 'Change Department coming soon',
            type: NecToastType.info,
          );
        },
      },
      {
        'label': 'Change Team',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          NecToast.show(
            context,
            message: 'Change Team coming soon',
            type: NecToastType.info,
          );
        },
      },
      {
        'label': 'Change Reporting Manager',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          NecToast.show(
            context,
            message: 'Change Reporting Manager coming soon',
            type: NecToastType.info,
          );
        },
      },
      {
        'label': 'Change Role',
        'color': nec.textPrimary,
        'onTap': () {
          Navigator.pop(context);
          NecToast.show(
            context,
            message: 'Change Role coming soon',
            type: NecToastType.info,
          );
        },
      },
      {
        'label': 'Deactivate Employee',
        'color': AppColors.error,
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
