import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/data/system_settings_store.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_ui.dart';

class AttendanceHomeCard extends StatefulWidget {
  const AttendanceHomeCard({super.key});

  @override
  State<AttendanceHomeCard> createState() => _AttendanceHomeCardState();
}

class _AttendanceHomeCardState extends State<AttendanceHomeCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          AttendanceStore.instance,
          SystemSettingsStore.instance,
          _pulseController,
        ]),
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final store = AttendanceStore.instance;
          final active = store.activeRecord(EmployeeStore.currentEmployeeId);
          final facts = store.dayFor(
            EmployeeStore.currentEmployeeId,
            active?.day ?? store.checkInDay,
          );
          final record = facts.record;
          final isWorking = facts.status == AttendanceStatus.working;

          final workedMins = facts.workedMinutes;
          final hours = workedMins ~/ 60;
          final mins = workedMins % 60;
          final workedDurationText =
              '${hours}h ${mins.toString().padLeft(2, '0')}m';

          final requiredMins =
              facts.requiredMinutes > 0 ? facts.requiredMinutes : 480;
          final progress = (workedMins / requiredMins).clamp(0.0, 1.0);
          final progressPercent = (progress * 100).toInt();

          final checkInStr = record?.checkIn != null
              ? DateFormat('hh:mm a').format(record!.checkIn!)
              : '--:--';

          final shiftWindowStr =
              '${AttendanceClock.minutesTime(store.policy.startMinutes)} – ${AttendanceClock.minutesTime(store.policy.endMinutes)}';

          final statusColor = attendanceColor(facts.status);

          return Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/attendance'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWorking
                        ? nec.brand.withValues(alpha: 0.3)
                        : nec.separator.withValues(alpha: 0.15),
                    width: isWorking ? 1.5 : 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: nec.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.clock_fill,
                            color: nec.brand,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Attendance',
                                style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Daily work tracker',
                                style: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                                alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isWorking)
                                FadeTransition(
                                  opacity: Tween<double>(begin: 0.35, end: 1.0)
                                      .animate(_pulseController),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                facts.status.label,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: nec.textTertiary,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          workedDurationText,
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'worked today',
                          style: TextStyle(
                            color: nec.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            color:
                                progress >= 1.0 ? AppColors.success : nec.brand,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    nec.brand,
                                    progress >= 1.0
                                        ? AppColors.success
                                        : nec.brand.withValues(alpha: 0.75),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : nec.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: _StatColumn(
                              label: 'Shift',
                              value: shiftWindowStr,
                              icon: CupertinoIcons.clock_fill,
                              iconColor: const Color(0xFF2563EB),
                              nec: nec,
                              fontSize: 11.5,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: nec.separator.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            flex: 8,
                            child: _StatColumn(
                              label: 'Check-in',
                              value: checkInStr,
                              icon: CupertinoIcons.arrow_right_circle_fill,
                              iconColor: const Color(0xFF10B981),
                              nec: nec,
                              fontSize: 12.0,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: nec.separator.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            flex: 8,
                            child: _StatColumn(
                              label: 'Overtime',
                              value: facts.overtimeMinutes > 0
                                  ? '+${facts.overtimeMinutes}m OT'
                                  : '0m',
                              icon: CupertinoIcons.sparkles,
                              iconColor: const Color(0xFFF59E0B),
                              nec: nec,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final NecColors nec;
  final double fontSize;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.nec,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 10, color: iconColor),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: nec.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: nec.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
