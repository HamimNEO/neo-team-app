import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../attendance/presentation/widgets/attendance_ui.dart';
import '../../team/data/department_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/data/team_store.dart';
import 'widgets/my_department_sheet.dart';
import 'widgets/my_team_sheet.dart';

class StaffAccessScreen extends StatefulWidget {
  final bool editable;

  const StaffAccessScreen({super.key, this.editable = false});

  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    EmployeeStore.instance.load();
    DepartmentStore.instance.load();
    TeamStore.instance.load();
  }

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
      animation: Listenable.merge([
        DemoSession.instance,
        StaffAccessStore.instance,
        EmployeeStore.instance,
        DepartmentStore.instance,
        TeamStore.instance,
      ]),
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = StaffAccessStore.instance;
        final editing = widget.editable && DemoSession.instance.isAdmin;
        final session = DemoSession.instance;
        final currentEmp = EmployeeStore.instance.byId(session.employeeId);

        return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(
                context, editing ? 'Staff Access' : 'My Workspace'),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Text(
                      editing
                          ? 'Changes save automatically and apply to every staff demo login.'
                          : 'Your administrator controls these permissions. Personal profile, department hierarchy, and account settings remain available.',
                      style: TextStyle(
                          color: nec.textSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 12),
                  if (!editing && currentEmp != null) ...[
                    const AttendanceHeading('My Workspace Units'),
                    _buildWorkspaceUnitCard(
                      context: context,
                      title: 'My Department',
                      subtitle: currentEmp.department.isNotEmpty
                          ? currentEmp.department.split(' · ').first
                          : 'Software Engineering',
                      badge: 'View Members & Roles',
                      icon: CupertinoIcons.building_2_fill,
                      accentColor: nec.brand,
                      onTap: () => MyDepartmentSheet.show(context, currentEmp),
                      nec: nec,
                    ),
                    const SizedBox(height: 10),
                    _buildWorkspaceUnitCard(
                      context: context,
                      title: 'My Team',
                      subtitle: currentEmp.team.isNotEmpty
                          ? currentEmp.team
                          : 'Assigned Team',
                      badge: 'View Roster & Lead',
                      icon: CupertinoIcons.person_3_fill,
                      accentColor: const Color(0xFF5856D6),
                      onTap: () => MyTeamSheet.show(context, currentEmp),
                      nec: nec,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  const AttendanceHeading('Feature Modules'),
                  _group(
                      StaffPermission.values
                          .where((permission) => permission.parent == null)
                          .toList(),
                      editing,
                      nec),
                  const AttendanceHeading('Create & Edit Rights'),
                  _group(
                      StaffPermission.values
                          .where((permission) => permission.parent != null)
                          .toList(),
                      editing,
                      nec),
                ]));
      });

  Widget _buildWorkspaceUnitCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required NecColors nec,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: nec.separator.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: nec.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: nec.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
