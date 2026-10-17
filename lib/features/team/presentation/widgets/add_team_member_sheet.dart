import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/employee_store.dart';
import '../../data/team_store.dart';
import '../../domain/models/employee.dart';

class AddTeamMemberSheet extends StatefulWidget {
  const AddTeamMemberSheet(
      {super.key, required this.teamName, this.onMemberAdded});

  final String teamName;
  final ValueChanged<String>? onMemberAdded;

  @override
  State<AddTeamMemberSheet> createState() => _AddTeamMemberSheetState();
}

class _AddTeamMemberSheetState extends State<AddTeamMemberSheet> {
  final _store = EmployeeStore.instance;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _store.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _add(Employee employee) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _store.assignTeam(employee, widget.teamName);
      await TeamStore.instance.load();
      if (!mounted) return;
      NecToast.show(context,
          message:
              result.warning ?? 'Added ${employee.name} to ${widget.teamName}',
          type: result.warning == null
              ? NecToastType.success
              : NecToastType.info);
      widget.onMemberAdded?.call(employee.id);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final candidates = _store.employees
        .where((e) =>
            e.team != widget.teamName &&
            e.status == 'Active' &&
            e.backendId != null)
        .toList();
    return PopScope(
        canPop: !_saving,
        child: Container(
            height: MediaQuery.of(context).size.height * 0.68,
            decoration: BoxDecoration(
                color: nec.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Material(
                color: Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                    child: Column(children: [
                  const SizedBox(height: 10),
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: nec.textTertiary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('Add Team Member',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary)),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: nec.separator),
                  if (_saving || _store.loading)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_error != null || _store.loadError != null)
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          Text(_error ?? _store.loadError!),
                          TextButton(
                              onPressed: _saving ? null : _store.load,
                              child: const Text('Retry'))
                        ])),
                  Expanded(
                      child: candidates.isEmpty
                          ? Center(
                              child: Text(_store.loading
                                  ? 'Loading employees…'
                                  : 'No available employees to add.'))
                          : ListView.separated(
                              itemCount: candidates.length,
                              separatorBuilder: (_, index) => Divider(
                                  height: 1,
                                  color: nec.separator.withValues(alpha: 0.2),
                                  indent: 72),
                              itemBuilder: (context, index) {
                                final employee = candidates[index];
                                return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 4),
                                    leading: NecAvatar(
                                        initials: employee.avatarInitials,
                                        photoBase64: employee.photoBase64,
                                        photoUrl: employee.photoUrl,
                                        size: 38),
                                    title: Text(employee.name,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary)),
                                    subtitle: Text(employee.designation,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: nec.textTertiary)),
                                    onTap:
                                        _saving ? null : () => _add(employee));
                              })),
                  const SizedBox(height: 12),
                ])))));
  }
}
