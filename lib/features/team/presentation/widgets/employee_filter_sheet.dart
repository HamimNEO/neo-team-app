import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeFilterSheet extends StatefulWidget {
  final String? selectedDepartment;
  final String? selectedRole;
  final String? selectedStatus;
  final Function(String? department, String? role, String? status) onApply;

  const EmployeeFilterSheet({
    super.key,
    this.selectedDepartment,
    this.selectedRole,
    this.selectedStatus,
    required this.onApply,
  });

  @override
  State<EmployeeFilterSheet> createState() => _EmployeeFilterSheetState();
}

class _EmployeeFilterSheetState extends State<EmployeeFilterSheet> {
  String? _department;
  String? _role;
  String? _status;

  final departments = [
    'All',
    'Sales',
    'Marketing',
    'Development',
    'Support',
    'Management',
  ];

  final roles = [
    'All',
    'Administrator',
    'Manager',
    'Lead',
    'Employee',
  ];

  final statuses = [
    'All',
    'Active',
    'On Leave',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();
    _department = widget.selectedDepartment ?? 'All';
    _role = widget.selectedRole ?? 'All';
    _status = widget.selectedStatus ?? 'All';
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
          padding: const EdgeInsets.all(16),
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
                  'Filter Employees',
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
                'DEPARTMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: departments.map((dept) {
                  final isSelected = _department == dept ||
                      (_department == null && dept == 'All');
                  final unselectedBg =
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _department = dept == 'All' ? null : dept;
                      });
                      widget.onApply(_department, _role, _status);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? nec.brand.withValues(alpha: 0.15)
                            : unselectedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? nec.brand
                              : nec.separator.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        dept,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? nec.brand : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'SYSTEM ROLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((r) {
                  final isSelected =
                      _role == r || (_role == null && r == 'All');
                  final unselectedBg =
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _role = r == 'All' ? null : r;
                      });
                      widget.onApply(_department, _role, _status);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? nec.brand.withValues(alpha: 0.15)
                            : unselectedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? nec.brand
                              : nec.separator.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? nec.brand : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((st) {
                  final isSelected =
                      _status == st || (_status == null && st == 'All');
                  final unselectedBg =
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _status = st == 'All' ? null : st;
                      });
                      widget.onApply(_department, _role, _status);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? nec.brand.withValues(alpha: 0.15)
                            : unselectedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? nec.brand
                              : nec.separator.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        st,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? nec.brand : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _department = null;
                      _role = null;
                      _status = null;
                    });
                    widget.onApply(null, null, null);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
