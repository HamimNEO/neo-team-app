import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/employee_store.dart';
import '../domain/models/employee.dart';
import '../domain/models/employee_salary.dart';
import 'widgets/employee_personal_fields.dart';
import 'widgets/employee_salary_draft.dart';
import 'widgets/employee_salary_step.dart';
import 'widgets/add_employee_step1.dart';
import 'widgets/add_employee_step2.dart';
import 'widgets/add_employee_step3.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String? employeeId;

  const AddEmployeeScreen({super.key, this.employeeId});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  int _currentStep = 1;
  bool _isLoading = false;
  bool _saved = false;
  bool _photoBusy = false;
  final _personalKey = GlobalKey<FormState>();
  final _salaryKey = GlobalKey<FormState>();
  late final EmployeePersonalDraft _personal;
  late final EmployeeSalaryDraft _salary;
  Employee? _original;
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _joiningDateController = TextEditingController();
  String? _selectedDepartment = 'Marketing';
  String? _selectedTeam = 'Marketing Team';
  String? _selectedManager = 'Mahmud Hasan';
  String? _selectedManagerId = 'emp_mahmud';
  String _selectedStatus = 'Active';
  String _selectedRole = 'Employee';

  @override
  void initState() {
    super.initState();
    _original = widget.employeeId == null
        ? null
        : EmployeeStore.instance.byId(widget.employeeId!);
    _personal = EmployeePersonalDraft(_original);
    _salary = EmployeeSalaryDraft(
      _original?.salary,
      enableByDefault: widget.employeeId == null,
      initialIsMealFree: _original?.isMealFree ?? true,
      initialMealCoPayPercent: _original?.mealCoPayPercent ?? 0,
      initialTotalMealCost: _original?.totalMealCost ?? 300000,
      initialHasRotationalReserve: _original?.hasRotationalReserve ?? false,
      initialRotationalReserveAmount: _original?.rotationalReserveAmount ?? 0,
    );
    _personal.name.addListener(_refresh);
    _personal.email.addListener(_refresh);
    _designationController.addListener(_refresh);
    _salary.addListener(_refresh);
    final employee = _original;
    if (employee != null) {
      _employeeIdController.text = employee.displayCode;
      _designationController.text = employee.designation;
      _joiningDateController.text = employee.joinedDate;
      _selectedDepartment = employee.department.split(' · ').first;
      _selectedTeam = employee.team;
      _selectedManager =
          EmployeeStore.instance.byId(employee.reportsToId ?? '')?.name ??
              employee.reportsTo;
      _selectedManagerId = employee.reportsToId ?? '';
      _selectedStatus = employee.status;
      _selectedRole = employee.systemRole;
    } else {
      _employeeIdController.text = EmployeeStore.instance.nextEmployeeCode;
      _joiningDateController.text =
          DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _continuePersonal() {
    FocusScope.of(context).unfocus();
    if (!(_personalKey.currentState?.validate() ?? false)) return;
    if (EmployeeStore.instance.employees.any((employee) =>
        employee.id != widget.employeeId &&
        employee.email.toLowerCase() ==
            _personal.email.text.trim().toLowerCase())) {
      NecToast.show(context,
          message: 'This work email is already in use.',
          type: NecToastType.error);
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _continueEmployment() {
    FocusScope.of(context).unfocus();
    if (_employeeIdController.text.trim().isEmpty ||
        _designationController.text.trim().isEmpty ||
        _joiningDateController.text.trim().isEmpty ||
        _selectedDepartment == null ||
        _selectedTeam == null) {
      NecToast.show(context,
          message: 'Complete the required employment details.',
          type: NecToastType.error);
      return;
    }
    if (EmployeeStore.instance.employees.any((employee) =>
        employee.id != widget.employeeId &&
        employee.displayCode.toLowerCase() ==
            _employeeIdController.text.trim().toLowerCase())) {
      NecToast.show(context,
          message: 'This employee ID is already in use.',
          type: NecToastType.error);
      return;
    }
    setState(() => _currentStep = 3);
  }

  void _continueSalary() {
    FocusScope.of(context).unfocus();
    if (_salary.enabled && !(_salaryKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_salary.enabled && _salary.buildSalary().net < 0) {
      NecToast.show(context,
          message: 'Deductions cannot exceed gross salary.',
          type: NecToastType.error);
      return;
    }
    setState(() => _currentStep = 4);
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading || _photoBusy) return;
    setState(() => _isLoading = true);
    try {
      final manager =
          _selectedManagerId == null || _selectedManagerId == widget.employeeId
              ? null
              : EmployeeStore.instance.byId(_selectedManagerId!);
      final employee = Employee(
        id: _original?.id ?? 'emp_${DateTime.now().microsecondsSinceEpoch}',
        employeeCode: _employeeIdController.text.trim(),
        name: _personal.name.text.trim(),
        email: _personal.email.text.trim(),
        phone: _personal.phone.text.trim(),
        avatarInitials: Employee.initialsFor(_personal.name.text),
        photoBase64: _personal.photo,
        designation: _designationController.text.trim(),
        department: _selectedDepartment!,
        team: _selectedTeam!,
        systemRole: _selectedRole,
        status: _selectedStatus,
        joinedDate: _joiningDateController.text.trim(),
        reportsTo: manager?.name,
        reportsToId: manager?.id,
        reportsToTitle: manager?.designation,
        reportsToAvatar: manager?.avatarInitials,
        address: _personal.address.text.trim(),
        dateOfBirth: _personal.dateOfBirth.text,
        emergencyContactName: _personal.emergencyName.text.trim(),
        emergencyContactPhone: _personal.emergencyPhone.text.trim(),
        salary: _salary.enabled ? _salary.buildSalary() : null,
        isMealFree: _salary.isMealFree,
        mealCoPayPercent: _salary.isMealFree ? 0 : _salary.mealCoPayPercent,
        totalMealCost: EmployeeSalary.parseAmount(_salary.totalMealCost.text) ?? 300000,
        hasRotationalReserve: _salary.hasRotationalReserve,
        rotationalReserveAmount: _salary.hasRotationalReserve
            ? (EmployeeSalary.parseAmount(_salary.rotationalReserveAmount.text) ?? 0)
            : 0,
        activeLeadsCount: _original?.activeLeadsCount ?? 0,
        activeTasksCount: _original?.activeTasksCount ?? 0,
        directReports: _original?.directReports,
      );
      await EmployeeStore.instance.save(employee);
      if (!mounted) return;
      NecToast.show(context,
          message: widget.employeeId == null
              ? 'Employee added successfully'
              : 'Employee details updated successfully',
          type: NecToastType.success);
      setState(() => _saved = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message
                : 'Unable to save employee details. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _personal.dispose();
    _salary.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEdit = widget.employeeId != null;

    if (isEdit && _original == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Employee unavailable')),
          body: const Center(child: Text('This employee could not be found.')));
    }
    return PopScope(
        canPop: _saved || (!_isLoading && _currentStep == 1),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_isLoading) _handleBack();
        },
        child: Scaffold(
          backgroundColor: nec.bg,
          appBar: AppBar(
            backgroundColor: nec.bg,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _handleBack,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.back,
                          size: 16,
                          color: nec.brand,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: nec.brand,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isEdit ? 'Edit Employee' : 'Add Employee',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Step Indicator Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final step = index + 1;
                            final isActive = step == _currentStep;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 24 : 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? nec.brand
                                    : nec.textTertiary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 68),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: nec.separator.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ),
          ),
          body: SafeArea(
            child: AbsorbPointer(
                absorbing: _isLoading,
                child: IndexedStack(
                  index: _currentStep - 1,
                  children: [
                    AddEmployeeStep1(
                      draft: _personal,
                      formKey: _personalKey,
                      busy: _photoBusy,
                      onPhotoBusyChanged: (value) =>
                          setState(() => _photoBusy = value),
                      onPhotoChanged: _refresh,
                      onContinue: _continuePersonal,
                    ),
                    AddEmployeeStep2(
                      editingEmployeeId: widget.employeeId,
                      employeeIdController: _employeeIdController,
                      designationController: _designationController,
                      joiningDateController: _joiningDateController,
                      selectedDepartment: _selectedDepartment,
                      selectedTeam: _selectedTeam,
                      selectedManager: _selectedManager,
                      selectedManagerId: _selectedManagerId,
                      onManagerIdChanged: (id) =>
                          setState(() => _selectedManagerId = id),
                      selectedStatus: _selectedStatus,
                      onDepartmentChanged: (v) => setState(() {
                        _selectedDepartment = v;
                        _selectedTeam = {
                          'Management': 'Executive',
                          'Marketing': 'Marketing Team',
                          'Sales': 'Hospitality Sales',
                          'Development': 'NEONECY Dev',
                          'Support': 'Support Team'
                        }[v];
                      }),
                      onTeamChanged: (v) => setState(() => _selectedTeam = v),
                      onManagerChanged: (v) =>
                          setState(() => _selectedManager = v),
                      onStatusChanged: (v) =>
                          setState(() => _selectedStatus = v),
                      onContinue: _continueEmployment,
                    ),
                    EmployeeSalaryStep(
                        draft: _salary,
                        formKey: _salaryKey,
                        onContinue: _continueSalary),
                    AddEmployeeStep3(
                      employeeName: _personal.name.text.trim(),
                      employeeEmail: _personal.email.text.trim(),
                      employeeCode: _employeeIdController.text.trim(),
                      salary: _salary.enabled ? _salary.buildSalary() : null,
                      selectedRole: _selectedRole,
                      onRoleChanged: (v) => setState(() => _selectedRole = v),
                      onSubmit: _handleSubmit,
                      isLoading: _isLoading,
                      isEditMode: isEdit,
                    ),
                  ],
                )),
          ),
        ));
  }
}
