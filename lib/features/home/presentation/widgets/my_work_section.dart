import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class MyWorkSection extends StatelessWidget {
  final bool showTasks;
  final bool showIssues;
  const MyWorkSection(
      {super.key, this.showTasks = true, this.showIssues = true});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (showTasks)
          InkWell(
            onTap: () => context.go('/tasks'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_rectangle,
                      color: AppColors.brandLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '2 due today',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '3',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                ],
              ),
            ),
          ),
          if (showTasks && showIssues)
          Divider(
              height: 1,
              color: nec.separator.withValues(alpha: 0.3),
              indent: 66),
          if (showIssues)
          InkWell(
            onTap: () => context.push('/issues'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_octagon,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issues',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '2 high priority',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '2',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
