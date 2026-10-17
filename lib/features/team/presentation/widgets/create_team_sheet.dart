import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/department_store.dart';
import '../../data/employee_store.dart';
import '../../data/team_store.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/team_group.dart';
import '../../../auth/presentation/controllers/auth_session.dart';

class CreateTeamSheet extends StatefulWidget {
  const CreateTeamSheet({super.key});

  @override
  State<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<CreateTeamSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _employeeStore = EmployeeStore.instance;
  final _deptStore = DepartmentStore.instance;

  final Set<String> _selectedEmployeeIds = {};
  final Set<String> _assignedEmployeeIds = {};
  TeamGroup? _createdTeam;
  String? _departmentId, _leadId;
  late final String? _actorToken;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _actorToken = AuthSession.instance.accessToken;
    _employeeStore.addListener(_refresh);
    _deptStore.addListener(_refresh);
    _employeeStore.load();
    _deptStore.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _employeeStore.removeListener(_refresh);
    _deptStore.removeListener(_refresh);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a team name');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_actorToken != AuthSession.instance.accessToken) {
        throw const FormatException(
            'Your account changed. Reopen Create Team.');
      }
      final employeesToAssign = _employeeStore.employees
          .where((e) => _selectedEmployeeIds.contains(e.id))
          .toList();

      final created = _createdTeam ??= await TeamStore.instance.create(
          name: name,
          departmentId: _departmentId,
          leadId: _leadId,
          description: _descriptionController.text);

      for (final emp in employeesToAssign) {
        if (_actorToken != AuthSession.instance.accessToken) {
          throw const FormatException(
              'Your account changed. Reopen Create Team.');
        }
        if (_assignedEmployeeIds.contains(emp.id)) continue;
        await _employeeStore.assignTeam(emp, created.name);
        _assignedEmployeeIds.add(emp.id);
      }

      await TeamStore.instance.load();
      if (!mounted) return;

      NecToast.show(
        context,
        message:
            'Team "$name" created successfully with ${employeesToAssign.length} members',
        type: NecToastType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            '${_createdTeam == null ? '' : 'Team created. Remaining member assignments could not be completed. '}${EmployeeStore.messageFor(e)}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final activeEmployees = _employeeStore.employees
        .where((e) => e.status == 'Active' && e.backendId != null)
        .toList();

    return PopScope(
      canPop: !_saving,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: nec.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Create Team',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const CupertinoActivityIndicator()
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  color: AppColors.brandLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.3),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'TEAM DETAILS',
                        style: TextStyle(
                          color: nec.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: nec.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          enabled: !_saving && _createdTeam == null,
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. Mobile Engineering Team',
                            hintStyle: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                          initialValue: _departmentId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Department (optional)'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: null, child: Text('No department')),
                            for (final department in _deptStore.departments)
                              DropdownMenuItem(
                                  value: department.id,
                                  child: Text(department.name,
                                      overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: _saving || _createdTeam != null
                              ? null
                              : (value) =>
                                  setState(() => _departmentId = value)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _leadId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Team lead (optional)'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: null, child: Text('Not assigned')),
                            for (final employee in activeEmployees)
                              DropdownMenuItem(
                                  value: employee.id,
                                  child: Text(employee.name,
                                      overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: _saving || _createdTeam != null
                              ? null
                              : (value) => setState(() => _leadId = value)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _descriptionController,
                          enabled: !_saving && _createdTeam == null,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              labelText: 'Description (optional)')),
                      const SizedBox(height: 20),
                      Text(
                        'SELECT INITIAL MEMBERS (${_selectedEmployeeIds.length} SELECTED)',
                        style: TextStyle(
                          color: nec.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Members are optional. You can create the team now and add employees later.',
                        style: TextStyle(
                          color: nec.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (activeEmployees.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No active employees available.',
                              style: TextStyle(
                                color: nec.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: nec.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < activeEmployees.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 52,
                                    color: nec.separator.withValues(alpha: 0.2),
                                  ),
                                _buildEmployeeTile(
                                  nec: nec,
                                  employee: activeEmployees[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeTile({
    required NecColors nec,
    required Employee employee,
  }) {
    final isSelected = _selectedEmployeeIds.contains(employee.id);

    return InkWell(
      onTap: _saving
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedEmployeeIds.remove(employee.id);
                } else {
                  _selectedEmployeeIds.add(employee.id);
                }
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            NecAvatar(
              initials: employee.avatarInitials,
              photoUrl: employee.photoUrl,
              photoBase64: employee.photoBase64,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${employee.designation}${employee.team.isNotEmpty ? ' · Current: ${employee.team}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? AppColors.brandLight : nec.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
