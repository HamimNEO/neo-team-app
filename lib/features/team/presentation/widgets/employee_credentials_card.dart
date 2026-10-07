import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/employee_store.dart';
import '../../domain/models/employee.dart';

class EmployeeCredentialsCard extends StatelessWidget {
  final Employee employee;

  const EmployeeCredentialsCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation:
            Listenable.merge([EmployeeStore.instance, DemoSession.instance]),
        builder: (context, _) {
          final session = DemoSession.instance;
          final own = employee.id == session.employeeId;
          if (!session.signedIn || (!session.isAdmin && !own)) {
            return const SizedBox.shrink();
          }
          final nec = Theme.of(context).extension<NecColors>()!;
          final manageStaff = session.isAdmin &&
              EmployeeStore.instance.isStaffEmployee(employee.id);
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (session.isAdmin)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('LOGIN CREDENTIALS',
                                      style: TextStyle(
                                          color: nec.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  SelectableText(
                                      EmployeeStore.instance
                                          .loginEmailFor(employee.id),
                                      style: TextStyle(
                                          color: nec.textPrimary,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text(
                                      manageStaff
                                          ? 'Password protected. Verify your admin password to view or change it.'
                                          : 'Administrator passwords are managed by their account owner.',
                                      style: TextStyle(
                                          color: nec.textTertiary,
                                          fontSize: 12,
                                          height: 1.4)),
                                ])),
                      if (manageStaff || own)
                        ListTile(
                          leading: Icon(CupertinoIcons.lock_shield,
                              color: nec.brand),
                          title: Text(manageStaff && !own
                              ? 'View & Change Password'
                              : 'Change Password'),
                          trailing: const Icon(CupertinoIcons.chevron_right,
                              size: 16),
                          onTap: () => context.pushAppRoute(manageStaff && !own
                              ? '/employee/${employee.id}/password'
                              : '/change-password'),
                        ),
                    ])),
          );
        },
      );
}
