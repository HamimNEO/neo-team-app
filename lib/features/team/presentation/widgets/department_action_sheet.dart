import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

enum DepartmentAction { addMember, edit, toggleActive, delete }

class DepartmentActionSheet extends StatelessWidget {
  const DepartmentActionSheet({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    Widget action(String label, DepartmentAction value, Color color) => InkWell(
          onTap: () => Navigator.pop(context, value),
          child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color)),
              )),
        );
    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: nec.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        action('Add Member to Department', DepartmentAction.addMember,
            AppColors.brandLight),
        Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
        action('Edit Department', DepartmentAction.edit, nec.brand),
        Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
        action(active ? 'Deactivate Department' : 'Activate Department',
            DepartmentAction.toggleActive, nec.textPrimary),
        Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
        action('Delete Department', DepartmentAction.delete, AppColors.error),
        const SizedBox(height: 12),
      ])),
    );
  }
}
