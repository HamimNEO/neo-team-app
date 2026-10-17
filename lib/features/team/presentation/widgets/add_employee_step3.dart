import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../domain/models/employee_role.dart';
import '../../domain/models/employee_salary.dart';
import '../../../auth/domain/models/employee_login.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import 'add_employee_picker_sheet.dart';
import 'employee_details_section.dart';
import 'employee_salary_summary.dart';

class AddEmployeeStep3 extends StatelessWidget {
  const AddEmployeeStep3(
      {super.key,
      required this.selectedRole,
      required this.employeeName,
      required this.employeeEmail,
      required this.employeeCode,
      this.salary,
      required this.onRoleChanged,
      required this.onSubmit,
      required this.isLoading,
      this.isEditMode = false,
      required this.needsPassword,
      required this.credentialsFormKey,
      required this.passwordController,
      required this.confirmPasswordController,
      required this.roles,
      this.roleError,
      required this.onRetryRoles,
      required this.accessScope,
      required this.onAccessScopeChanged,
      this.error});

  final String selectedRole,
      employeeName,
      employeeEmail,
      employeeCode,
      accessScope;
  final String? roleError, error;
  final EmployeeSalary? salary;
  final ValueChanged<String> onRoleChanged, onAccessScopeChanged;
  final VoidCallback onSubmit, onRetryRoles;
  final bool isLoading, isEditMode, needsPassword;
  final GlobalKey<FormState> credentialsFormKey;
  final TextEditingController passwordController, confirmPasswordController;
  final List<EmployeeRole> roles;

  void _chooseRole(BuildContext context) => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddEmployeePickerSheet(
          title: 'System Role',
          selectedValue: selectedRole,
          options: roles
              .map((role) => PickerOption(title: role.name, value: role.key))
              .toList(),
          onSelected: (option) => onRoleChanged(option.value!)));

  Widget _choice(
      BuildContext context, String label, String value, VoidCallback onTap) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary)),
            const SizedBox(height: 6),
            InkWell(
                onTap: isLoading ? null : onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: nec.separator)),
                  child: Row(children: [
                    Expanded(
                        child: Text(value,
                            style: TextStyle(
                                fontSize: 15, color: nec.textPrimary))),
                    Icon(CupertinoIcons.chevron_down,
                        size: 16, color: nec.textTertiary)
                  ]),
                )),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final role = roles.where((item) => item.key == selectedRole).firstOrNull;
    return Form(
        key: credentialsFormKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EmployeeDetailsSection(title: 'Review employee', rows: [
              ('Full Name', employeeName),
              ('Work Email', employeeEmail),
              ('Employee ID', employeeCode)
            ]),
            const SizedBox(height: 20),
            if (salary != null) ...[
              EmployeeSalarySummary(salary: salary!),
              const SizedBox(height: 20)
            ],
            if (needsPassword) ...[
              Text('Login Credentials',
                  style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'The work email is the login ID. Share this temporary password with the employee; they must change it on first login.',
                  style: TextStyle(
                      color: nec.textSecondary, fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
              PasswordField(
                  label: 'Create Password *',
                  controller: passwordController,
                  validator: (value) =>
                      EmployeeLogin.passwordError(value ?? '')),
              PasswordField(
                  label: 'Confirm Password *',
                  controller: confirmPasswordController,
                  validator: (value) => value == passwordController.text &&
                          (value?.isNotEmpty ?? false)
                      ? null
                      : 'Passwords do not match.'),
              const SizedBox(height: 16),
            ],
            _choice(context, 'System Role', role?.name ?? selectedRole,
                () => _chooseRole(context)),
            if (roleError != null) ...[
              Text(roleError!,
                  style: TextStyle(color: nec.textSecondary, fontSize: 13)),
              TextButton(
                  onPressed: onRetryRoles, child: const Text('Retry roles')),
            ],
            _choice(
                context,
                'Access Scope',
                {
                      'assigned': 'Assigned work',
                      'team': 'Team work',
                      'all': 'All work'
                    }[accessScope] ??
                    accessScope,
                () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddEmployeePickerSheet(
                        title: 'Access Scope',
                        selectedValue: accessScope,
                        options: const [
                          PickerOption(
                              title: 'Assigned work', value: 'assigned'),
                          PickerOption(title: 'Team work', value: 'team'),
                          PickerOption(title: 'All work', value: 'all')
                        ],
                        onSelected: (option) =>
                            onAccessScopeChanged(option.value!)))),
            if (role?.modules.isNotEmpty == true)
              EmployeeDetailsSection(
                  title: 'Role permissions',
                  rows: role!.modules
                      .map((module) => (
                            module['label']?.toString() ??
                                module['key'].toString(),
                            '${module['granted'] ?? '—'}/${module['total'] ?? '—'} granted'
                          ))
                      .toList())
            else
              Text(
                  'Module access follows the selected role and can be reviewed on the employee profile after saving.',
                  style: TextStyle(color: nec.textSecondary, fontSize: 13)),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 32),
            NecButton(
                label: isEditMode ? 'Save Changes' : 'Add Employee',
                onPressed: onSubmit,
                fullWidth: true,
                loading: isLoading),
            const SizedBox(height: 24),
          ]),
        ));
  }
}
