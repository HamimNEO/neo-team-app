import '../../../../core/router/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/domain/models/employee.dart';
import '../../../team/presentation/widgets/employee_details_section.dart';
import 'session_section.dart';

class ProfileMoreTab extends StatelessWidget {
  final Employee employee;

  const ProfileMoreTab({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(children: [
          EmployeeDetailsSection(title: 'Account', rows: [
            ('Login Email', DemoSession.instance.email),
            ('Work Email', employee.email),
            (
              'System Role',
              DemoSession.instance.isAdmin
                  ? 'Administrator'
                  : employee.systemRole
            ),
            (
              'Access',
              DemoSession.instance.isAdmin
                  ? 'Full administration'
                  : 'Managed by administrator'
            ),
            ('Account Status', employee.status),
          ]),
          const SizedBox(height: 20),
          Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                if (StaffAccessStore.instance
                    .allows(StaffPermission.meals)) ...[
                  ListTile(
                      leading: Icon(CupertinoIcons.cart, color: nec.brand),
                      title: Text(DemoSession.instance.isAdmin
                          ? 'Lunch Management'
                          : 'My Office Lunch'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.pushAppRoute(
                          DemoSession.instance.isAdmin
                              ? '/meals/admin'
                              : '/meals')),
                  Divider(height: 1, color: nec.separator),
                ],
                if (StaffAccessStore.instance
                    .allows(StaffPermission.attendance)) ...[
                  ListTile(
                      leading: Icon(CupertinoIcons.calendar, color: nec.brand),
                      title: Text(DemoSession.instance.isAdmin
                          ? 'Attendance Management'
                          : 'My Attendance'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.pushAppRoute(
                          DemoSession.instance.isAdmin
                              ? '/attendance/admin'
                              : '/attendance')),
                  Divider(height: 1, color: nec.separator),
                ],
                ListTile(
                    leading:
                        Icon(CupertinoIcons.square_pencil, color: nec.brand),
                    title: const Text('Edit Profile'),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => context.pushAppRoute('/edit-profile')),
                Divider(height: 1, color: nec.separator),
                ListTile(
                    leading: Icon(CupertinoIcons.lock_shield, color: nec.brand),
                    title: const Text('Change Password'),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => context.pushAppRoute('/change-password')),
                Divider(height: 1, color: nec.separator),
                ListTile(
                    leading: Icon(CupertinoIcons.lock_shield, color: nec.brand),
                    title: const Text('Account & Security'),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => context.pushAppRoute('/account-security')),
              ])),
          const SessionSection(),
        ]));
  }
}
