import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/management_summary_card.dart';
import '../../../attendance/data/attendance_clock.dart';
import '../../../attendance/data/attendance_store.dart';
import '../../../settings/data/system_settings_store.dart';
import '../../../team/data/employee_store.dart';
import '../../data/meal_store.dart';
import '../../domain/models/lunch_preference.dart';

class _LunchArtPainter extends CustomPainter {
  final bool isDark;

  _LunchArtPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final auraColor =
        isDark ? const Color(0xFF3B2A1E) : const Color(0xFFFFEDD5);
    const accentColor = Color(0xFFF97316);

    final auraPaint = Paint()
      ..color = auraColor.withValues(alpha: isDark ? 0.45 : 0.75)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.60, size.height * 0.60);
    final radius = size.height * 0.68;
    canvas.drawCircle(center, radius, auraPaint);

    final sparkPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.22),
      Offset(size.width * 0.22, size.height * 0.12),
      sparkPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.15),
      Offset(size.width * 0.38, size.height * 0.02),
      sparkPaint,
    );

    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.65 : 0.80)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.70), 3.0, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.28, size.height * 0.85), 2.2, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.25), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LunchArtPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

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
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
          final progress = (available && eligible > 0) ? count / eligible : 0.0;
          final percentInt = (progress * 100).round();

          const accent = Color(0xFF34C759);
          final metric1Bg =
              isDark ? const Color(0xFF0F3A22) : const Color(0xFFE6F7EC);
          final metric2Bg = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6);
          final metric2Fg =
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);

          return ManagementSummaryCard(
            title: 'Lunch Management',
            subtitle: 'Office lunch · Today',
            icon: CupertinoIcons.cart_fill,
            accent: accent,
            metrics: [
              ManagementMetricItem(
                icon: CupertinoIcons.tray_fill,
                iconBg: metric1Bg,
                iconColor: accent,
                value: available ? '$count' : '—',
                label: 'Lunches to provide',
              ),
              ManagementMetricItem(
                icon: CupertinoIcons.person_badge_minus,
                iconBg: metric2Bg,
                iconColor: metric2Fg,
                value: available ? '$skipped' : '—',
                label: 'Skipping lunch',
              ),
            ],
            progress: available ? progress : 0,
            percentageText: available ? '$percentInt%' : '0%',
            progressLabel: !available
                ? 'Lunch data unavailable'
                : eligible == 0
                    ? 'No staff lunches scheduled today'
                    : '$eligible staff eligible · ${active.length - eligible} not scheduled',
            onTap: () => context.push('/meals/admin'),
          );
        }

        final status =
            MealStore.instance.statusFor(EmployeeStore.currentEmployeeId, day);
        final statusLabel = status.label;

        return Material(
          color: isDark ? const Color(0xFF231B15) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/meals'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B2A1E)
                      : const Color(0xFFFFEDD5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B2A1E)
                              : const Color(0xFFFFE8D6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          CupertinoIcons.cart_fill,
                          color: Color(0xFFF97316),
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF97316),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'My Office Lunch',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: nec.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tomorrow · $statusLabel',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 68,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LunchArtPainter(isDark: isDark),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          child: Transform.rotate(
                            angle: 0.35,
                            child: Image.asset(
                              'assets/others/lunch_employee.png',
                              height: 42,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B2A1E)
                          : const Color(0xFFFFEDD5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.chevron_right,
                      color: Color(0xFFEA580C),
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
}
