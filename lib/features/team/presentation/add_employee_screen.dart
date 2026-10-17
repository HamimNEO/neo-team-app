import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/employee_store.dart';
import '../data/department_store.dart';
import '../domain/models/employee_role.dart';
import '../domain/models/employee_submission.dart';
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
  bool _initializing = true;
  String? _formError, _initialError;
  final _store = EmployeeStore.instance;
  final _personalKey = GlobalKey<FormState>();
  final _salaryKey = GlobalKey<FormState>();
  final _credentialsKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _needsPassword => widget.employeeId == null;
  late final EmployeePersonalDraft _personal;
  late final EmployeeSalaryDraft _salary;
  Employee? _original;
  final _employeeIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _joiningDateController = TextEditingController();
  String? _selectedDepartment, _selectedDepartmentId;
  String? _selectedTeam;
  String? _selectedManager;
  String? _selectedManagerId;
  String _selectedStatus = 'Active';
  String _selectedRole = EmployeeRole.operations.key;
  String _accessScope = 'assigned';
  String _selectedEmploymentType = 'permanent';
  final _probationStartDateController = TextEditingController();
  final _probationEndDateController = TextEditingController();
  String? _agreementPdfName;
  String? _agreementPdfBase64;
  int? _agreementPdfSizeBytes;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Future.wait(
          [_store.load(), _store.loadRoles(), DepartmentStore.instance.load()]);
      if (!mounted) return;
      if (widget.employeeId != null) {
        _original = await _store.loadDetails(widget.employeeId!);
        if (!mounted) return;
        if (_original == null) {
          throw const FormatException('This employee is unavailable.');
        }
      }
      _personal = EmployeePersonalDraft(_original);
      _salary = EmployeeSalaryDraft(_original?.salary,
          enableByDefault: widget.employeeId == null,
          initialIsMealFree: _original?.isMealFree ?? true,
          initialMealCoPayPercent: _original?.mealCoPayPercent ?? 0,
          initialTotalMealCost: _original?.totalMealCost ?? 300000,
          initialHasRotationalReserve: _original?.hasRotationalReserve ?? false,
          initialRotationalReserveAmount:
              _original?.rotationalReserveAmount ?? 0);
      _personal.name.addListener(_refresh);
      _personal.email.addListener(_refresh);
      _designationController.addListener(_refresh);
      _salary.addListener(_refresh);
      final employee = _original;
      if (employee != null) {
        _employeeIdController.text = employee.employeeCode;
        _designationController.text = employee.designation;
        _joiningDateController.text = employee.joinedDate;
        _selectedDepartment = employee.department;
        _selectedDepartmentId = employee.departmentId;
        _selectedTeam = employee.team;
        _selectedManager = employee.reportsTo;
        _selectedManagerId = employee.reportsToId;
        _selectedStatus = employee.status;
        _selectedRole = employee.roleKey ?? EmployeeRole.operations.key;
        _accessScope = employee.accessScope ?? 'assigned';
        _selectedEmploymentType = employee.employmentType;
        _probationStartDateController.text =
            employee.probationStartDate ?? employee.joinedDate;
        _probationEndDateController.text = employee.probationEndDate ?? '';
        _agreementPdfName = employee.agreementPdfName;
        _agreementPdfBase64 = employee.agreementPdfBase64;
        _agreementPdfSizeBytes = employee.agreementPdfSizeBytes;
      } else {
        _employeeIdController.text = _store.nextEmployeeCode;
        _joiningDateController.text =
            DateTime.now().toIso8601String().substring(0, 10);
        _selectedEmploymentType = 'permanent';
        _probationStartDateController.text = _joiningDateController.text;
        final now = DateTime.now();
        _probationEndDateController.text =
            DateTime(now.year, now.month + 3, now.day)
                .toIso8601String()
                .substring(0, 10);
      }
    } catch (exception) {
      _initialError = EmployeeStore.messageFor(exception);
    } finally {
      if (mounted) setState(() => _initializing = false);
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
        _selectedDepartmentId == null ||
        (_selectedTeam?.trim().isEmpty ?? true)) {
      NecToast.show(context,
          message: 'Complete the required employment details.',
          type: NecToastType.error);
      return;
    }
    if (_selectedEmploymentType == 'probation') {
      if (_probationStartDateController.text.trim().isEmpty ||
          _probationEndDateController.text.trim().isEmpty) {
        NecToast.show(context,
            message: 'Specify the probation start and end dates.',
            type: NecToastType.error);
        return;
      }
      final start = DateTime.tryParse(_probationStartDateController.text);
      final end = DateTime.tryParse(_probationEndDateController.text);
      if (start != null && end != null && end.isBefore(start)) {
        NecToast.show(context,
            message: 'Probation end date must be after start date.',
            type: NecToastType.error);
        return;
      }
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
    if (widget.employeeId == null &&
        _salary.enabled &&
        !(_salaryKey.currentState?.validate() ?? false)) {
      return;
    }
    if (widget.employeeId == null &&
        _salary.enabled &&
        (EmployeeSalary.parseAmount(_salary.totalMealCost.text) == null ||
            (_salary.hasRotationalReserve &&
                EmployeeSalary.parseAmount(
                        _salary.rotationalReserveAmount.text) ==
                    null))) {
      NecToast.show(context,
          message: 'Enter valid meal and reserve amounts.',
          type: NecToastType.error);
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
    FocusScope.of(context).unfocus();
    if (_needsPassword &&
        !(_credentialsKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
      _formError = null;
    });
    try {
      final manager =
          _selectedManagerId == null || _selectedManagerId == widget.employeeId
              ? null
              : EmployeeStore.instance.byId(_selectedManagerId!);
      final employee = Employee(
        id: _original?.id ?? '',
        employeeCode: _employeeIdController.text.trim(),
        name: _personal.name.text.trim(),
        email: _personal.email.text.trim(),
        phone: _personal.phone.text.trim(),
        avatarInitials: Employee.initialsFor(_personal.name.text),
        photoBase64:
            _personal.photo != _original?.photoBase64 ? _personal.photo : null,
        designation: _designationController.text.trim(),
        department: _selectedDepartment ?? '',
        departmentId: _selectedDepartmentId,
        team: _selectedTeam!,
        systemRole: _selectedRole,
        roleKey: _selectedRole,
        accessScope: _accessScope,
        status: _selectedStatus,
        joinedDate: _joiningDateController.text.trim(),
        employmentType: _selectedEmploymentType,
        probationStartDate: _selectedEmploymentType == 'probation'
            ? _probationStartDateController.text.trim()
            : null,
        probationEndDate: _selectedEmploymentType == 'probation'
            ? _probationEndDateController.text.trim()
            : null,
        agreementPdfName: _agreementPdfName,
        agreementPdfBase64: _agreementPdfBase64,
        agreementPdfSizeBytes: _agreementPdfSizeBytes,
        reportsTo: manager?.name,
        reportsToId: manager?.id,
        reportsToTitle: manager?.designation,
        reportsToAvatar: manager?.avatarInitials,
        address: _personal.address.text.trim(),
        dateOfBirth: _personal.dateOfBirth.text,
        emergencyContactName: _personal.emergencyName.text.trim(),
        emergencyContactPhone: _personal.emergencyPhone.text.trim(),
        salary: _salary.enabled ? _salary.buildSalary() : null,
        companyMealEnabled: widget.employeeId == null
            ? _salary.enabled
            : (_original?.companyMealEnabled ?? false),
        isMealFree: _salary.isMealFree,
        mealCoPayPercent: _salary.isMealFree ? 0 : _salary.mealCoPayPercent,
        totalMealCost:
            EmployeeSalary.parseAmount(_salary.totalMealCost.text) ?? 0,
        hasRotationalReserve: _salary.hasRotationalReserve,
        rotationalReserveAmount: _salary.hasRotationalReserve
            ? (EmployeeSalary.parseAmount(
                    _salary.rotationalReserveAmount.text) ??
                0)
            : 0,
        activeLeadsCount: _original?.activeLeadsCount ?? 0,
        activeTasksCount: _original?.activeTasksCount ?? 0,
        directReports: _original?.directReports,
      );
      final result = await _store.submit(
          EmployeeSubmission(
              employee: employee,
              roleKey: _selectedRole,
              accessScope: _accessScope,
              password: _needsPassword ? _passwordController.text : null),
          original: _original);
      if (!mounted) return;
      NecToast.show(context,
          message: result.warning ??
              _store.cacheError ??
              (widget.employeeId == null
                  ? 'Employee added successfully'
                  : 'Employee details updated successfully'),
          type: result.warning == null
              ? NecToastType.success
              : NecToastType.info);
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _saved = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _formError = EmployeeStore.messageFor(error));
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _store.removeListener(_refresh);
    if (!_initializing && _initialError == null) {
      _personal.dispose();
      _salary.dispose();
    }
    _employeeIdController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    _probationStartDateController.dispose();
    _probationEndDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEdit = widget.employeeId != null;

    if (_initializing || _initialError != null) {
      return Scaffold(
          backgroundColor: nec.bg,
          appBar:
              AppBar(title: Text(isEdit ? 'Edit Employee' : 'Add Employee')),
          body: Center(
              child: _initializing
                  ? const CupertinoActivityIndicator()
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_initialError!, textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _initialError = null;
                              _initializing = true;
                            });
                            _initialize();
                          },
                          child: const Text('Retry'))
                    ])));
    }
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
                      editing: isEdit,
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
                      selectedDepartmentId: _selectedDepartmentId,
                      onDepartmentIdChanged: (value) =>
                          setState(() => _selectedDepartmentId = value),
                      selectedTeam: _selectedTeam,
                      selectedManager: _selectedManager,
                      selectedManagerId: _selectedManagerId,
                      onManagerIdChanged: (id) =>
                          setState(() => _selectedManagerId = id),
                      selectedStatus: _selectedStatus,
                      onDepartmentChanged: (v) => setState(() {
                        _selectedDepartment = v;
                        _selectedTeam = null;
                      }),
                      onTeamChanged: (v) => setState(() => _selectedTeam = v),
                      onManagerChanged: (v) =>
                          setState(() => _selectedManager = v),
                      onStatusChanged: (v) =>
                          setState(() => _selectedStatus = v),
                      employmentType: _selectedEmploymentType,
                      onEmploymentTypeChanged: (v) =>
                          setState(() => _selectedEmploymentType = v),
                      probationStartDateController:
                          _probationStartDateController,
                      probationEndDateController:
                          _probationEndDateController,
                      agreementPdfName: _agreementPdfName,
                      agreementPdfBase64: _agreementPdfBase64,
                      agreementPdfSizeBytes: _agreementPdfSizeBytes,
                      onAgreementPdfPicked: ({
                        required fileName,
                        required base64Data,
                        required sizeBytes,
                      }) =>
                          setState(() {
                        _agreementPdfName = fileName;
                        _agreementPdfBase64 = base64Data;
                        _agreementPdfSizeBytes = sizeBytes;
                      }),
                      onAgreementPdfRemoved: () => setState(() {
                        _agreementPdfName = null;
                        _agreementPdfBase64 = null;
                        _agreementPdfSizeBytes = null;
                      }),
                      onContinue: _continueEmployment,
                    ),
                    EmployeeSalaryStep(
                        draft: _salary,
                        editable: !isEdit,
                        formKey: _salaryKey,
                        onContinue: _continueSalary),
                    AddEmployeeStep3(
                      needsPassword: _needsPassword,
                      credentialsFormKey: _credentialsKey,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      employeeName: _personal.name.text.trim(),
                      employeeEmail: _personal.email.text.trim(),
                      employeeCode: _employeeIdController.text.trim(),
                      salary: _salary.enabled ? _salary.buildSalary() : null,
                      selectedRole: _selectedRole,
                      roles: [
                        ..._store.roles,
                        if (!_store.roles
                            .any((role) => role.key == _selectedRole))
                          EmployeeRole(
                              key: _selectedRole,
                              name: _original?.systemRole ?? 'Operations'),
                      ],
                      roleError: _store.roleError,
                      onRetryRoles: _store.loadRoles,
                      accessScope: _accessScope,
                      onAccessScopeChanged: (value) =>
                          setState(() => _accessScope = value),
                      error: _formError,
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
