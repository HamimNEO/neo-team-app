import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/data/work_item_store.dart';

class MyWorkSection extends StatelessWidget {
  final bool showTasks;
  final bool showIssues;

  const MyWorkSection(
      {super.key, this.showTasks = true, this.showIssues = true});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedBuilder(
      animation: WorkItemStore.instance,
      builder: (context, _) {
        final summary = WorkItemStore.instance.overview.summary;
        final work = WorkItemStore.instance;
        final openTasks = work.hasOverview ? summary.openTasks : work.openTasks;
        final openIssues =
            work.hasOverview ? summary.openIssues : work.openIssues;

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$openTasks open',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$openTasks',
                          style: const TextStyle(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$openIssues open',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$openIssues',
                          style: const TextStyle(
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
      },
    );
  }
}
