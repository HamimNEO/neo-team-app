import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/department_store.dart';
import '../data/employee_store.dart';
import '../domain/models/department.dart';
import '../domain/models/employee.dart';
import 'widgets/add_department_member_sheet.dart';
import 'widgets/create_department_sheet.dart';
import 'widgets/department_action_sheet.dart';
import 'widgets/department_load_status.dart';

class DepartmentDetailsScreen extends StatefulWidget {
  const DepartmentDetailsScreen({super.key, required this.departmentId});

  final String departmentId;

  @override
  State<DepartmentDetailsScreen> createState() =>
      _DepartmentDetailsScreenState();
}

class _DepartmentDetailsScreenState extends State<DepartmentDetailsScreen> {
  final _store = DepartmentStore.instance;
  DepartmentItem? _detail;
  String? _detailError, _actionError;
  bool _loading = false, _busy = false;
  int _request = 0;
  int _detailAccount = -1;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(DepartmentDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.departmentId != oldWidget.departmentId) {
      _detail = null;
      _load();
    }
  }

  @override
  void dispose() {
    _request++;
    _store.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    final id = widget.departmentId;
    setState(() {
      _loading = true;
      _detailError = null;
    });
    await _store.load();
    if (!mounted || request != _request) return;
    try {
      final detail = await _store.details(id);
      if (mounted && request == _request) {
        setState(() {
          _detail = detail;
          _detailAccount = _store.accountVersion;
        });
      }
    } catch (exception) {
      if (mounted && request == _request) {
        setState(() => _detailError = DepartmentStore.messageFor(exception));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _actions(DepartmentItem department) async {
    final action = await showModalBottomSheet<DepartmentAction>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            DepartmentActionSheet(active: department.isActive == true));
    if (!mounted || action == null) return;
    switch (action) {
      case DepartmentAction.addMember:
        await _openAddMemberSheet(department);
      case DepartmentAction.edit:
        final result = await showModalBottomSheet<DepartmentItem>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => CreateDepartmentSheet(department: department));
        if (mounted && result != null) {
          _detail = null;
          NecToast.show(context,
              message: 'Department updated', type: NecToastType.success);
          _load();
        }
      case DepartmentAction.toggleActive:
        await _toggleActive(department);
      case DepartmentAction.delete:
        await _delete(department);
    }
  }

  Future<void> _openAddMemberSheet(DepartmentItem department) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddDepartmentMemberSheet(
        departmentId: department.id,
        departmentName: department.name,
        onMemberAdded: (_) {
          _load();
          EmployeeStore.instance.load();
        },
      ),
    );
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
                title: Text(title),
                content: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(message)),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(action)),
                ],
              )) ??
      false;

  Future<void> _toggleActive(DepartmentItem department) async {
    if (_busy || _store.saving) return;
    final active = department.isActive != true;
    final action = active ? 'Activate' : 'Deactivate';
    if (!await _confirm(
            '$action Department', '$action ${department.name}?', action) ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await _store.save(
          department: department,
          name: department.name,
          code: department.code!,
          active: active);
      if (!mounted) return;
      _detail = null;
      NecToast.show(context,
          message: active ? 'Department activated' : 'Department deactivated',
          type: NecToastType.success);
      _load();
    } catch (exception) {
      if (mounted) {
        setState(() => _actionError = DepartmentStore.messageFor(exception));
        NecToast.show(context,
            message: _actionError!, type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(DepartmentItem department) async {
    if (_busy || _store.saving) return;
    if (!await _confirm(
            'Delete Department',
            'Permanently delete ${department.name}? Employees must be reassigned before this department can be deleted.',
            'Delete') ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await _store.delete(department.id);
      if (!mounted) return;
      NecToast.show(context,
          message: 'Department deleted', type: NecToastType.success);
      context.pop();
    } catch (exception) {
      if (mounted) {
        setState(() => _actionError = DepartmentStore.messageFor(exception));
        NecToast.show(context,
            message: _actionError!, type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMember(Employee employee) async {
    if (_busy || !_store.canManage || employee.backendId == null) return;
    if (!await _confirm('Remove Member',
            'Remove ${employee.name} from this department?', 'Remove') ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await _store.removeMember(widget.departmentId, employee.backendId!);
      await EmployeeStore.instance.load();
      if (!mounted) return;
      await _load();
      if (mounted) {
        NecToast.show(context,
            message: 'Department member removed', type: NecToastType.success);
      }
    } catch (e) {
      if (mounted) setState(() => _actionError = DepartmentStore.messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final base = _store.byId(widget.departmentId);
    final detail = base == null ||
            _detailAccount != _store.accountVersion ||
            _detail?.name != base.name
        ? null
        : _detail;
    final canManage = base != null &&
        base.code != null &&
        base.isActive != null &&
        _store.canManage;
    final rows = <(String, String)>[
      if (base != null) ('Name', base.name),
      if (base?.code != null) ('Code', base!.code!),
      if (detail?.leadName != null) ('Department Lead', detail!.leadName!),
      if (detail?.memberCount != null)
        ('Members', '${detail!.memberCount} employees'),
      if (detail?.teamCount != null) ('Teams', '${detail!.teamCount} teams'),
      if (base?.status != null) ('Status', base!.status!),
    ];
    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back_ios, size: 16, color: nec.brand),
                    const SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(color: nec.brand, fontSize: 16)),
                  ])),
              Expanded(
                  child: Text(base?.name ?? 'Department',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600))),
              SizedBox(
                  width: 68,
                  child: canManage
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _busy || _store.saving
                              ? null
                              : () => _actions(base),
                          child:
                              Icon(CupertinoIcons.ellipsis, color: nec.brand))
                      : null),
            ])),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                height: 1, color: nec.separator.withValues(alpha: 0.3))),
      ),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DepartmentLoadStatus(
                          loading: _loading,
                          error: _store.error ?? _store.cacheError,
                          onRetry: _load),
                      if (base == null && !_loading)
                        Text(
                            'This department is unavailable. Refresh to try again.',
                            style: TextStyle(color: nec.textSecondary)),
                      if (rows.isNotEmpty)
                        Material(
                            color: nec.surface,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: Column(children: [
                              for (var index = 0;
                                  index < rows.length;
                                  index++) ...[
                                if (index > 0)
                                  Divider(
                                      height: 1,
                                      indent: 16,
                                      color:
                                          nec.separator.withValues(alpha: 0.2)),
                                _infoRow(nec, rows[index].$1, rows[index].$2),
                              ],
                            ])),
                      if (_detailError != null)
                        DepartmentLoadStatus(
                            loading: false,
                            error:
                                'Additional department information is unavailable. $_detailError',
                            onRetry: _load),
                      if (detail?.description != null) ...[
                        const SizedBox(height: 16),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: nec.surface,
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('DESCRIPTION',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: nec.textSecondary)),
                                  const SizedBox(height: 8),
                                  Text(detail!.description!,
                                      style: TextStyle(
                                          fontSize: 14.5,
                                          height: 1.35,
                                          color: nec.textPrimary)),
                                ])),
                      ],
                      if (detail?.memberCount != null ||
                          detail?.teamCount != null) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          if (detail?.memberCount != null)
                            _stat(nec, '${detail!.memberCount}', 'Members',
                                AppColors.brandLight),
                          if (detail?.memberCount != null &&
                              detail?.teamCount != null)
                            const SizedBox(width: 12),
                          if (detail?.teamCount != null)
                            _stat(nec, '${detail!.teamCount}', 'Teams',
                                AppColors.leadContacted),
                        ]),
                      ],
                      if (canManage) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddMemberSheet(base),
                            icon: const Icon(CupertinoIcons.person_badge_plus,
                                size: 18),
                            label: const Text('Add Member to Department',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'DEPARTMENT MEMBERS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: nec.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        if (base == null) return const SizedBox.shrink();
                        final deptEmployees = detail?.members ??
                            EmployeeStore.instance.employees.where((e) {
                              if (e.departmentId != null &&
                                  e.departmentId == base.id) {
                                return true;
                              }
                              if (e.department
                                  .toLowerCase()
                                  .contains(base.name.toLowerCase())) {
                                return true;
                              }
                              return false;
                            }).toList();

                        if (deptEmployees.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'No members assigned to this department yet.',
                                style: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          );
                        }

                        return Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < deptEmployees.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 64,
                                    color: nec.separator.withValues(alpha: 0.2),
                                  ),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading: NecAvatar(
                                    initials: deptEmployees[i].avatarInitials,
                                    photoUrl: deptEmployees[i].photoUrl,
                                    photoBase64: deptEmployees[i].photoBase64,
                                    size: 40,
                                  ),
                                  title: Text(
                                    deptEmployees[i].name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    deptEmployees[i].designation,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: nec.textTertiary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 16,
                                    color: nec.textTertiary,
                                  ),
                                  onTap: () => context
                                      .push('/employee/${deptEmployees[i].id}'),
                                  onLongPress: canManage && !_busy
                                      ? () => _removeMember(deptEmployees[i])
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      if (_actionError != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(_actionError!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      if (canManage) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _busy || _store.saving
                                  ? null
                                  : () => _toggleActive(base),
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: AppColors.error
                                          .withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              child: _busy
                                  ? const CupertinoActivityIndicator()
                                  : Text(
                                      base.isActive == true
                                          ? 'Deactivate Department'
                                          : 'Activate Department',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error)),
                            )),
                      ],
                      const SizedBox(height: 32),
                    ]),
              ))),
    );
  }

  Widget _infoRow(NecColors nec, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(label,
              style: TextStyle(fontSize: 14.5, color: nec.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary))),
        ]),
      );

  Widget _stat(NecColors nec, String value, String label, Color color) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: nec.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: nec.textTertiary)),
        ]),
      ));
}
