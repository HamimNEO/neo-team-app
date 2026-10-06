import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
        final day = AttendanceClock.key(
            AttendanceClock.today.add(Duration(days: administrator ? 0 : 1)));
        final count = EmployeeStore.instance.employees
            .where((employee) =>
                employee.status == 'Active' &&
                MealStore.instance.statusFor(employee.id, day) ==
                    LunchStatus.receiving)
            .length;
        return AttendanceCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(CupertinoIcons.cart, color: nec.brand),
              title: Text(
                  administrator ? 'Lunch Management' : 'My Office Lunch',
                  style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                  administrator
                      ? '$count lunches needed today'
                      : 'Tomorrow · ${MealStore.instance.statusFor(EmployeeStore.currentEmployeeId, day).label}',
                  style: TextStyle(color: nec.textSecondary, fontSize: 12)),
              trailing: Icon(CupertinoIcons.chevron_right,
                  color: nec.textTertiary, size: 14),
              onTap: () =>
                  context.push(administrator ? '/meals/admin' : '/meals'),
            ));
      });
}
