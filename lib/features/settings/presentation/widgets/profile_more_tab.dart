import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/domain/models/employee.dart';
import '../../../team/presentation/widgets/employee_details_section.dart';

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
            ('Work Email', employee.email),
            ('System Role', employee.systemRole),
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
                      title: const Text('My Office Lunch'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.push('/meals')),
                  Divider(height: 1, color: nec.separator),
                ],
                if (StaffAccessStore.instance
                    .allows(StaffPermission.attendance)) ...[
                  ListTile(
                      leading: Icon(CupertinoIcons.calendar, color: nec.brand),
                      title: const Text('My Attendance'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.push('/attendance')),
                  Divider(height: 1, color: nec.separator),
                ],
                ListTile(
                    leading:
                        Icon(CupertinoIcons.square_pencil, color: nec.brand),
                    title: const Text('Edit Profile'),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => context.push('/edit-profile')),
                Divider(height: 1, color: nec.separator),
                ListTile(
                    leading: Icon(CupertinoIcons.lock_shield, color: nec.brand),
                    title: const Text('Account & Security'),
                    trailing:
                        const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => context.push('/account-security')),
              ])),
        ]));
  }
}
