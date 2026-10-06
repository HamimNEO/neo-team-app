import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/employee_store.dart';
import '../../data/mock_employees.dart';
import '../../../auth/presentation/widgets/auth_field.dart';
import 'add_employee_picker_sheet.dart';

class AddEmployeeStep2 extends StatelessWidget {
  final TextEditingController employeeIdController;
  final TextEditingController designationController;
  final TextEditingController joiningDateController;
  final String? selectedDepartment;
  final String? selectedTeam;
  final String? selectedManager;
  final String? selectedManagerId;
  final ValueChanged<String?>? onManagerIdChanged;
  final String selectedStatus;
  final ValueChanged<String> onDepartmentChanged;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<String> onManagerChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onContinue;
  final String? editingEmployeeId;

  const AddEmployeeStep2({
    super.key,
    required this.employeeIdController,
    required this.designationController,
    required this.joiningDateController,
    required this.selectedDepartment,
    required this.selectedTeam,
    required this.selectedManager,
    this.selectedManagerId,
    this.onManagerIdChanged,
    required this.selectedStatus,
    required this.onDepartmentChanged,
    required this.onTeamChanged,
    required this.onManagerChanged,
    required this.onStatusChanged,
    required this.onContinue,
    this.editingEmployeeId,
  });

  void _showDepartmentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Select Department',
        selectedValue: selectedDepartment,
        options: const [
          PickerOption(title: 'Management'),
          PickerOption(title: 'Sales'),
          PickerOption(title: 'Marketing'),
          PickerOption(title: 'Development'),
          PickerOption(title: 'Support'),
        ],
        onSelected: (opt) => onDepartmentChanged(opt.title),
      ),
    );
  }

  void _showTeamPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Select Team',
        selectedValue: selectedTeam,
        options: [
          if (selectedDepartment == 'Management')
            const PickerOption(title: 'Executive'),
          ...mockTeams
              .where((team) => team.department == selectedDepartment)
              .map((team) => PickerOption(title: team.name)),
        ],
        onSelected: (opt) => onTeamChanged(opt.title),
      ),
    );
  }

  void _showManagerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Select Reporting Manager',
        selectedValue: selectedManagerId ?? selectedManager,
        options: [
          const PickerOption(title: 'Not assigned', value: ''),
          ...EmployeeStore.instance.employees
              .where((employee) =>
                  employee.status == 'Active' &&
                  employee.id != editingEmployeeId)
              .map((employee) => PickerOption(
                  title: employee.name,
                  value: employee.id,
                  subtitle:
                      '${employee.designation} · ${employee.displayCode}')),
        ],
        onSelected: (opt) {
          onManagerChanged(opt.title);
          onManagerIdChanged?.call(opt.value);
        },
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Employment Status',
        selectedValue: selectedStatus,
        options: const [
          PickerOption(title: 'Active'),
          PickerOption(title: 'Inactive'),
        ],
        onSelected: (opt) => onStatusChanged(opt.title),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String valueText,
    required VoidCallback onTap,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: nec.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
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
                Expanded(
                    child: Text(
                  valueText,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueText.startsWith('Select')
                        ? nec.textTertiary
                        : nec.textPrimary,
                  ),
                )),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: nec.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = designationController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthField(
            label: 'Employee ID *',
            hintText: 'e.g. NEC-EMP-008',
            controller: employeeIdController,
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'Designation *',
            hintText: 'e.g. Sales Executive',
            controller: designationController,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Department *',
            valueText: selectedDepartment ?? 'Select department',
            onTap: () => _showDepartmentPicker(context),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Team *',
            valueText: selectedTeam ?? 'Select team',
            onTap: () => _showTeamPicker(context),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Reporting Manager',
            valueText: selectedManager ?? 'Select manager',
            onTap: () => _showManagerPicker(context),
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'Joining Date *',
            hintText: 'Select joining date',
            controller: joiningDateController,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(joiningDateController.text) ??
                      DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100));
              if (context.mounted && date != null) {
                joiningDateController.text =
                    date.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Employment Status',
            valueText: selectedStatus,
            onTap: () => _showStatusPicker(context),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: 'Continue',
            onPressed: isValid ? onContinue : null,
            fullWidth: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
