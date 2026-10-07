import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/employee.dart';
import 'employee_credentials_card.dart';

class EmployeeMoreTab extends StatelessWidget {
  final Employee employee;

  const EmployeeMoreTab({
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

  Widget _buildRowItem(
      {required BuildContext context,
      required String label,
      required Widget valueWidget,
      VoidCallback? onTap,
      bool showDivider = true}) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return InkWell(
        onTap: onTap,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    flex: 2,
                    child: Text(label,
                        style:
                            TextStyle(fontSize: 14, color: nec.textSecondary))),
                const SizedBox(width: 12),
                Expanded(
                    flex: 3,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(child: valueWidget),
                          if (onTap != null) ...[
                            const SizedBox(width: 6),
                            Icon(CupertinoIcons.chevron_right,
                                size: 14, color: nec.textTertiary)
                          ],
                        ])),
              ])),
          if (showDivider) Divider(height: 1, color: nec.separator, indent: 16),
        ]));
  }

  String _access(String normal) {
    if (employee.systemRole == 'Administrator' ||
        employee.systemRole == 'Admin') {
      return 'Full Access';
    }
    if (employee.systemRole == 'Viewer') return 'Read Only';
    if (employee.systemRole == 'Manager' || employee.systemRole == 'Lead') {
      return 'Manage Team';
    }
    return normal;
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'PERSONAL INFORMATION'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Full Name',
                  valueWidget: Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
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
          _buildSectionHeader(context, 'EMPLOYMENT INFORMATION'),
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
                  label: 'Department',
                  valueWidget: Text(
                    employee.department,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () {},
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
                  onTap: () {},
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
                  showDivider: false,
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'DOCUMENTS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    NecToast.show(
                      context,
                      message: 'Opening Employment Agreement...',
                      type: NecToastType.info,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                            CupertinoIcons.doc_text_fill,
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
                                'Employment Agreement',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PDF · Jan 2022',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                  indent: 16,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.lock,
                        size: 14,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Some documents are restricted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'ROLE & PERMISSIONS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.designation,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'System Role',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.systemRole,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                  indent: 16,
                ),
                _buildPermissionRow(context, 'Leads', _access('View Assigned')),
                _buildPermissionRow(
                    context, 'Follow-ups', _access('Manage Assigned')),
                _buildPermissionRow(
                    context, 'Visits', _access('Manage Assigned')),
                _buildPermissionRow(
                    context, 'Tasks', _access('Manage Assigned')),
                _buildPermissionRow(context, 'Team', _access('View')),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                  indent: 16,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.lock,
                        size: 14,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Only admins can modify permissions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'ACCOUNT & SECURITY'),
          EmployeeCredentialsCard(employee: employee),
          const SizedBox(height: 12),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Account Email',
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
                  label: 'Account Status',
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
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
      BuildContext context, String label, String permissionText) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: nec.textSecondary,
                ),
              ),
              Text(
                permissionText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: nec.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: nec.separator.withValues(alpha: 0.3),
          indent: 16,
        ),
      ],
    );
  }
}
