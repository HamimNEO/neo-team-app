import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../attendance/presentation/widgets/attendance_ui.dart';

class StaffAccessScreen extends StatefulWidget {
  final bool editable;
  const StaffAccessScreen({super.key, this.editable = false});
  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  bool _saving = false;
  Future<void> _change(StaffPermission permission, bool value) async {
    setState(() => _saving = true);
    try {
      await StaffAccessStore.instance.setPermission(permission, value);
    } catch (error) {
      if (mounted) {
        attendanceError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation:
          Listenable.merge([DemoSession.instance, StaffAccessStore.instance]),
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = StaffAccessStore.instance;
        final editing = widget.editable && DemoSession.instance.isAdmin;
        return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(
                context, editing ? 'Staff Access' : 'My Access'),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Text(
                      editing
                          ? 'Changes save automatically and apply to every staff demo login.'
                          : 'Your administrator controls these permissions. Personal profile, appearance, and account settings remain available.',
                      style: TextStyle(
                          color: nec.textSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 12),
                  Text(
                      'Administration, employee management, payroll management, and organization settings are reserved for Admin.',
                      style: TextStyle(
                          color: nec.textTertiary, fontSize: 12, height: 1.5)),
                  if (store.loadError != null) ...[
                    const SizedBox(height: 12),
                    Text(store.loadError!,
                        style:
                            const TextStyle(color: CupertinoColors.systemRed))
                  ],
                  const AttendanceHeading('Modules'),
                  _group(
                      StaffPermission.values
                          .where((permission) => permission.parent == null)
                          .toList(),
                      editing,
                      nec),
                  const AttendanceHeading('Create & edit'),
                  _group(
                      StaffPermission.values
                          .where((permission) => permission.parent != null)
                          .toList(),
                      editing,
                      nec),
                ]));
      });
  Widget _group(
          List<StaffPermission> permissions, bool editing, NecColors nec) =>
      AttendanceCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var index = 0; index < permissions.length; index++) ...[
              if (index > 0)
                Divider(height: 1, color: nec.separator, indent: 16),
              ListTile(
                  title: Text(permissions[index].label,
                      style: TextStyle(color: nec.textPrimary, fontSize: 15)),
                  subtitle: Text(permissions[index].description,
                      style: TextStyle(color: nec.textSecondary, fontSize: 12)),
                  trailing: CupertinoSwitch(
                      value: StaffAccessStore.instance
                              .enabled(permissions[index]) &&
                          (permissions[index].parent == null ||
                              StaffAccessStore.instance
                                  .enabled(permissions[index].parent!)),
                      onChanged: editing &&
                              !_saving &&
                              StaffAccessStore.instance.loadError == null &&
                              (permissions[index].parent == null ||
                                  StaffAccessStore.instance
                                      .enabled(permissions[index].parent!))
                          ? (value) => _change(permissions[index], value)
                          : null)),
            ],
          ]));
}
