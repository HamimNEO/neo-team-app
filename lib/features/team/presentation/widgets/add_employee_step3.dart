import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import 'add_employee_picker_sheet.dart';
import '../../domain/models/employee_salary.dart';
import 'employee_details_section.dart';
import 'employee_salary_summary.dart';

class AddEmployeeStep3 extends StatelessWidget {
  final String selectedRole;
  final String employeeName;
  final String employeeEmail;
  final String employeeCode;
  final EmployeeSalary? salary;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool isEditMode;

  const AddEmployeeStep3({
    super.key,
    required this.selectedRole,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeCode,
    this.salary,
    required this.onRoleChanged,
    required this.onSubmit,
    required this.isLoading,
    this.isEditMode = false,
  });

  void _showRolePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'System Role',
        selectedValue: selectedRole,
        options: const [
          PickerOption(title: 'Administrator', subtitle: 'Full system access'),
          PickerOption(title: 'Lead', subtitle: 'Manage assigned team work'),
          PickerOption(
              title: 'Manager', subtitle: 'Manage team and assigned work'),
          PickerOption(
              title: 'Employee', subtitle: 'Access to assigned work only'),
          PickerOption(title: 'Viewer', subtitle: 'Read-only access'),
        ],
        onSelected: (opt) => onRoleChanged(opt.title),
      ),
    );
  }

  Widget _buildPermissionRow(BuildContext context, String label, String value,
      {bool showDivider = true}) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: nec.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(
                    fontSize: 13,
                    color: nec.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: nec.separator.withValues(alpha: 0.3),
              indent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeDetailsSection(title: 'Review employee', rows: [
            ('Full Name', employeeName),
            ('Work Email', employeeEmail),
            ('Employee ID', employeeCode),
          ]),
          const SizedBox(height: 20),
          if (salary != null) ...[
            EmployeeSalarySummary(salary: salary!),
            const SizedBox(height: 20),
          ],
          Text(
            'Assign a system role. The selected role determines the default permissions. Custom permissions can be adjusted after creation.',
            style: TextStyle(
              fontSize: 14,
              color: nec.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'System Role',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showRolePicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nec.separator, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedRole,
                    style: TextStyle(
                      fontSize: 15,
                      color: nec.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'DEFAULT ACCESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildPermissionRow(
                  context,
                  'Leads',
                  (selectedRole == 'Admin' || selectedRole == 'Administrator')
                      ? 'Full Access'
                      : (selectedRole == 'Manager'
                          ? 'Manage Team'
                          : 'View Assigned'),
                ),
                _buildPermissionRow(
                  context,
                  'Follow-ups',
                  (selectedRole == 'Admin' || selectedRole == 'Administrator')
                      ? 'Full Access'
                      : (selectedRole == 'Manager' || selectedRole == 'Lead'
                          ? 'Manage Team'
                          : selectedRole == 'Viewer'
                              ? 'Read Only'
                              : 'Manage Assigned'),
                ),
                _buildPermissionRow(
                  context,
                  'Visits',
                  (selectedRole == 'Admin' || selectedRole == 'Administrator')
                      ? 'Full Access'
                      : (selectedRole == 'Manager' || selectedRole == 'Lead'
                          ? 'Manage Team'
                          : selectedRole == 'Viewer'
                              ? 'Read Only'
                              : 'Manage Assigned'),
                ),
                _buildPermissionRow(
                  context,
                  'Team',
                  (selectedRole == 'Admin' || selectedRole == 'Administrator')
                      ? 'Full Access'
                      : 'View',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: isEditMode ? 'Save Changes' : 'Add Employee',
            onPressed: onSubmit,
            fullWidth: true,
            loading: isLoading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
