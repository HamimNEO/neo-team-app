import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/mock_employees.dart';

class CreateDepartmentSheet extends StatefulWidget {
  const CreateDepartmentSheet({super.key});

  @override
  State<CreateDepartmentSheet> createState() => _CreateDepartmentSheetState();
}

class _CreateDepartmentSheetState extends State<CreateDepartmentSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedLead;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showEmployeePicker() {
    final employees = mockEmployees.map((e) => e.name).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Department Lead',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
                ...employees.map(
                  (emp) => Column(
                    children: [
                      ListTile(
                        title: Text(
                          emp,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedLead == emp
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedLead == emp
                                ? nec.brand
                                : nec.textPrimary,
                          ),
                        ),
                        trailing: _selectedLead == emp
                            ? Icon(CupertinoIcons.checkmark,
                                color: nec.brand, size: 18)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLead = emp;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.15),
                        indent: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitDepartment() {
    if (_nameController.text.trim().isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a department name',
        type: NecToastType.error,
      );
      return;
    }

    final newDept = DepartmentItem(
      id: 'dept_${DateTime.now().millisecondsSinceEpoch % 1000}',
      name: _nameController.text.trim(),
      leadName: _selectedLead ?? 'Unassigned',
      memberCount: 1,
      teamCount: 1,
      description: _descController.text.trim().isEmpty
          ? 'Operations and team activities'
          : _descController.text.trim(),
      iconColor: AppColors.brandLight,
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newDept);
    }

    NecToast.show(
      context,
      message: 'Department created successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Create Department',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'DEPARTMENT NAME *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Operations',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DEPARTMENT LEAD',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showEmployeePicker,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color:
                        isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: nec.separator.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedLead ?? 'Select employee (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedLead != null
                              ? nec.textPrimary
                              : nec.textTertiary,
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Brief description (optional)',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              NecButton(
                label: 'Create Department',
                onPressed: _submitDepartment,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
