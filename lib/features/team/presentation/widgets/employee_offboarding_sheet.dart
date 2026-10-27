import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/employee_store.dart';
import '../../domain/models/employee.dart';

class EmployeeOffboardingSheet extends StatefulWidget {
  const EmployeeOffboardingSheet({super.key, required this.employee});

  final Employee employee;

  static Future<void> show(BuildContext context, Employee employee) =>
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => EmployeeOffboardingSheet(employee: employee));

  @override
  State<EmployeeOffboardingSheet> createState() =>
      _EmployeeOffboardingSheetState();
}

class _EmployeeOffboardingSheetState extends State<EmployeeOffboardingSheet> {
  final _store = EmployeeStore.instance;
  final _note = TextEditingController();
  Map<String, dynamic>? _summary;
  String? _error, _replacement;
  String _reason = 'disciplinary';
  bool _loading = true,
      _saving = false,
      _leads = true,
      _work = true,
      _reports = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _store.offboardingSummary(widget.employee);
      if (mounted) setState(() => _summary = result);
    } catch (error) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handover() async {
    final replacement = _store.byId(_replacement ?? '');
    if (replacement == null) return;
    setState(() => _saving = true);
    try {
      await _store.reassignWorkload(widget.employee, replacement,
          leads: _leads, workItems: _work, directReports: _reports);
      if (!mounted) return;
      NecToast.show(context, message: 'Workload reassigned');
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _suspend() async {
    if (_note.text.trim().isEmpty) {
      setState(() => _error = 'Enter a reason for suspending this account.');
      return;
    }
    final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialog) => CupertinoAlertDialog(
                title: Text('Suspend ${widget.employee.name}?'),
                content: const Text(
                    'This immediately disables access and revokes active sessions. Complete any required workload handover first.'),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Suspend'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _store.suspendEmployee(widget.employee, true,
          reasonType: _reason, reasonNote: _note.text.trim());
      if (!mounted) return;
      NecToast.show(context, message: 'Employee account suspended');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final replacements = _store.employees.where((e) =>
        e.backendId != null &&
        e.id != widget.employee.id &&
        e.status == 'Active');
    final raw = _summary?['open_work'] ??
        _summary?['summary'] ??
        _summary?['workload'] ??
        _summary?['data'] ??
        _summary;
    final counts = raw is Map
        ? raw.entries.where((entry) => entry.value is num).toList()
        : [];
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text('Offboarding · ${widget.employee.name}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              for (final entry in counts)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key.toString().replaceAll('_', ' ')),
                    trailing: Text('${entry.value}')),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                TextButton(
                    onPressed: _saving || _loading ? null : _load,
                    child: const Text('Retry summary'))
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                  initialValue: _replacement,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Replacement employee'),
                  items: [
                    for (final e in replacements)
                      DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _replacement = value)),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active leads'),
                  value: _leads,
                  onChanged:
                      _saving ? null : (v) => setState(() => _leads = v!)),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tasks, follow-ups and visits'),
                  value: _work,
                  onChanged:
                      _saving ? null : (v) => setState(() => _work = v!)),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Direct reports'),
                  value: _reports,
                  onChanged:
                      _saving ? null : (v) => setState(() => _reports = v!)),
              OutlinedButton(
                  onPressed: _saving ||
                          _replacement == null ||
                          !(_leads || _work || _reports)
                      ? null
                      : _handover,
                  child: const Text('Reassign selected workload')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  initialValue: _reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: const [
                    DropdownMenuItem(
                        value: 'resigned', child: Text('Resigned')),
                    DropdownMenuItem(
                        value: 'terminated', child: Text('Terminated')),
                    DropdownMenuItem(
                        value: 'disciplinary',
                        child: Text('Disciplinary suspension'))
                  ],
                  onChanged:
                      _saving ? null : (v) => setState(() => _reason = v!)),
              TextField(
                  controller: _note,
                  maxLines: 3,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                      labelText: 'Reason / handover note')),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _saving ? null : _suspend,
                  child: Text(_saving ? 'Saving…' : 'Suspend account')),
            ])));
  }
}
