import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/employee.dart';

class EmployeeCredentialsCard extends StatelessWidget {
  const EmployeeCredentialsCard({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final session = DemoSession.instance;
    if (!session.signedIn ||
        (!session.isAdmin && employee.id != session.employeeId)) {
      return const SizedBox.shrink();
    }
    final own = employee.id == session.employeeId;
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Material(
          color: nec.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOGIN ID',
                          style: TextStyle(
                              color: nec.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      SelectableText(employee.email,
                          style:
                              TextStyle(color: nec.textPrimary, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                          'Passwords are managed by the account owner and are never returned by the server.',
                          style: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 12,
                              height: 1.4)),
                    ])),
            if (own)
              ListTile(
                  leading: Icon(CupertinoIcons.lock_shield, color: nec.brand),
                  title: const Text('Change Password'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => context.pushAppRoute('/change-password')),
          ]),
        ));
  }
}
