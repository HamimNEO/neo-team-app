import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../domain/models/employee.dart';

class EmployeeOverviewTab extends StatelessWidget {
  final Employee employee;

  const EmployeeOverviewTab({
    super.key,
    required this.employee,
  });

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

  Widget _buildRowItem({
    required BuildContext context,
    required String label,
    required Widget valueWidget,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    valueWidget,
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: nec.textTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: nec.separator.withValues(alpha: 0.3),
              indent: 16,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'EMPLOYMENT'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Employee ID',
                  valueWidget: Text(
                    employee.displayCode,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Designation',
                  valueWidget: Text(
                    employee.designation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Status',
                  valueWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      employee.status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Joined',
                  valueWidget: Text(
                    employee.joinedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'System Role',
                  valueWidget: Text(
                    employee.systemRole,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Department',
                  valueWidget: Text(
                    employee.department,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () => context.push('/department/marketing'),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Team',
                  valueWidget: Text(
                    employee.team,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () => context.push('/team-details/marketing_team'),
                ),
                if (employee.reportsTo != null)
                  _buildRowItem(
                    context: context,
                    label: 'Reports To',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NecAvatar(
                          initials: employee.reportsToAvatar ?? 'MH',
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              employee.reportsTo!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                            if (employee.reportsToTitle != null)
                              Text(
                                employee.reportsToTitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: nec.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: employee.reportsToId != null
                        ? () =>
                            context.push('/employee/${employee.reportsToId}')
                        : null,
                    showDivider: false,
                  ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'CONTACT'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Work Email',
                  valueWidget: Text(
                    employee.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Phone',
                  valueWidget: Text(
                    employee.phone,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          if (employee.directReports != null &&
              employee.directReports!.isNotEmpty) ...[
            _buildSectionHeader(
                context, 'DIRECT REPORTS (${employee.directReports!.length})'),
            Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children:
                    List.generate(employee.directReports!.length, (index) {
                  final report = employee.directReports![index];
                  final isLast = index == employee.directReports!.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: NecAvatar(
                          initials: report.avatarInitials,
                          size: 38,
                        ),
                        title: Text(
                          report.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          report.designation,
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                        onTap: () => context.push('/employee/${report.id}'),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.3),
                          indent: 68,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
