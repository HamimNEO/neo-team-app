import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../more/data/notification_store.dart';
import '../../../team/data/employee_store.dart';
import 'home_header_painter.dart';
import 'home_profile_avatar.dart';
import 'home_theme_toggle.dart';

class SparkleAccentIcon extends StatelessWidget {
  const SparkleAccentIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 14,
      child: CustomPaint(
        painter: _SparklePainter(),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeGreetingBar extends StatelessWidget {
  final String greeting;
  final String userName;
  final String userInitials;
  final String dateString;

  const HomeGreetingBar({
    super.key,
    this.greeting = 'Good afternoon,',
    required this.userName,
    required this.userInitials,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        EmployeeStore.instance,
        NotificationStore.instance,
      ]),
      builder: (context, _) {
        if (!DemoSession.instance.signedIn) return const SizedBox.shrink();
        final employee = EmployeeStore.instance.currentEmployee;
        final period = getTimeOfDayPeriod();

        final (periodIcon, periodIconColor, greetingText) = switch (period) {
          TimeOfDayPeriod.morning => (
              Icons.wb_sunny_rounded,
              const Color(0xFFFFA726),
              'Good morning,',
            ),
          TimeOfDayPeriod.afternoon => (
              Icons.wb_sunny_rounded,
              const Color(0xFFFFA726),
              'Good afternoon,',
            ),
          TimeOfDayPeriod.evening => (
              Icons.wb_twilight_rounded,
              const Color(0xFFFF7043),
              'Good evening,',
            ),
          TimeOfDayPeriod.night => (
              Icons.nightlight_round,
              const Color(0xFF7E57C2),
              'Good night,',
            ),
        };

        final displayName = DemoSession.instance.isAdmin
            ? 'NEONECY'
            : (employee.name
                    .split(RegExp(r'\s+'))
                    .where((part) => !['Most.', 'Md.', 'MD.'].contains(part))
                    .firstOrNull ??
                employee.name);

        final topPadding = MediaQuery.of(context).padding.top;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: CustomPaint(
            painter: HomeHeaderPainter(
              period: period,
              isDark: isDark,
              bgColor: nec.bg,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFF3ECFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(periodIcon,
                                  size: 14, color: periodIconColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              greetingText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF6B58A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const HomeThemeToggle(),
                          const SizedBox(width: 6),
                          GlassCircleButton(
                            onPressed: () => context.push('/notifications'),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.bell,
                                  color: nec.textPrimary,
                                  size: 20,
                                ),
                                if (NotificationStore.instance.unreadCount > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFA855F7),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: HomeProfileAvatar(
                              employee: employee,
                              administrator: DemoSession.instance.isAdmin,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: nec.textPrimary,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: SparkleAccentIcon(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 14,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
