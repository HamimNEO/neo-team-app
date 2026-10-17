import 'package:flutter/material.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/employee_store.dart';
import '../../data/team_store.dart';
import '../../domain/models/team_group.dart';

class EditTeamSheet extends StatefulWidget {
  const EditTeamSheet({super.key, required this.team});

  final TeamGroup team;

  @override
  State<EditTeamSheet> createState() => _EditTeamSheetState();
}

class _EditTeamSheetState extends State<EditTeamSheet> {
  late final _name = TextEditingController(text: widget.team.name);
  late final _description =
      TextEditingController(text: widget.team.description ?? '');
  String? _lead;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lead = widget.team.lead?.backendId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter a team name.');
      return;
    }
    setState(() => _saving = true);
    try {
      await TeamStore.instance.update(widget.team, {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'lead_id': _lead == null ? null : int.parse(_lead!)
      });
      if (!mounted) return;
      NecToast.show(context, message: 'Team updated');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leads = EmployeeStore.instance.employees
        .where((e) => e.backendId != null && e.status == 'Active')
        .toList();
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Edit Team', style: Theme.of(context).textTheme.titleLarge),
          TextField(
              controller: _name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Team name')),
          TextField(
              controller: _description,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description')),
          DropdownButtonFormField<String>(
              initialValue:
                  leads.any((e) => e.backendId == _lead) ? _lead : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Team lead'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('Unassigned')),
                for (final e in leads)
                  DropdownMenuItem(
                      value: e.backendId,
                      child: Text(e.name, overflow: TextOverflow.ellipsis))
              ],
              onChanged: _saving ? null : (v) => setState(() => _lead = v)),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save changes')),
        ])));
  }
}
