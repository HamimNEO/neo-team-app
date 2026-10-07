import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/management_summary_card.dart';
import '../../../attendance/data/attendance_clock.dart';
import '../../../attendance/data/attendance_store.dart';
import '../../../attendance/presentation/widgets/attendance_ui.dart';
import '../../../settings/data/system_settings_store.dart';
import '../../../team/data/employee_store.dart';
import '../../data/meal_store.dart';
import '../../domain/models/lunch_preference.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';

class LunchEntry extends StatelessWidget {
  final bool administrator;

  const LunchEntry({super.key, this.administrator = false});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([
        MealStore.instance,
        AttendanceStore.instance,
        EmployeeStore.instance,
        SystemSettingsStore.instance
      ]),
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        if (!StaffAccessStore.instance.allows(StaffPermission.meals) ||
            (administrator && !DemoSession.instance.isAdmin)) {
          return const SizedBox.shrink();
        }
        final adminMode = administrator || DemoSession.instance.isAdmin;
        final day = AttendanceClock.key(
            AttendanceClock.today.add(Duration(days: adminMode ? 0 : 1)));
        final count = EmployeeStore.instance.staffEmployees
            .where((employee) =>
                employee.status == 'Active' &&
                MealStore.instance.statusFor(employee.id, day) ==
                    LunchStatus.receiving)
            .length;
        if (adminMode) {
          final active = EmployeeStore.instance.staffEmployees
              .where((employee) => employee.status == 'Active');
          final skipped = active
              .where((employee) =>
                  MealStore.instance.statusFor(employee.id, day) ==
                  LunchStatus.skipped)
              .length;
          final eligible = count + skipped;
          final available = MealStore.instance.loadError == null &&
              AttendanceStore.instance.loadError == null &&
              EmployeeStore.instance.loadError == null;
          return ManagementSummaryCard(
            title: 'Lunch Management',
            subtitle: 'Office lunch · Today',
            icon: CupertinoIcons.cart,
            accent: CupertinoColors.systemGreen,
            metrics: [
              (
                'Lunches to provide',
                available ? '$count' : '—',
                nec.textPrimary
              ),
              (
                'Skipping lunch',
                available ? '$skipped' : '—',
                skipped > 0 ? CupertinoColors.systemOrange : nec.textPrimary
              ),
            ],
            progress: available && eligible > 0 ? count / eligible : 0,
            progressLabel: !available
                ? 'Lunch data unavailable'
                : eligible == 0
                    ? 'No staff lunches scheduled today'
                    : '$eligible staff eligible · ${active.length - eligible} not scheduled',
            onTap: () => context.push('/meals/admin'),
          );
        }
        return AttendanceCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(CupertinoIcons.cart, color: nec.brand),
              title: Text(adminMode ? 'Lunch Management' : 'My Office Lunch',
                  style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                  adminMode
                      ? '$count lunches needed today'
                      : 'Tomorrow · ${MealStore.instance.statusFor(EmployeeStore.currentEmployeeId, day).label}',
                  style: TextStyle(color: nec.textSecondary, fontSize: 12)),
              trailing: Icon(CupertinoIcons.chevron_right,
                  color: nec.textTertiary, size: 14),
              onTap: () => context.push(adminMode ? '/meals/admin' : '/meals'),
            ));
      });
}
