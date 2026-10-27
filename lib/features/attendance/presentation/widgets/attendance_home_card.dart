import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          EmployeeStore.instance,
          SystemSettingsStore.instance,
          _pulseController,
        ]),
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final store = AttendanceStore.instance;
          final empId = EmployeeStore.currentEmployeeId;
          final active = store.activeRecord(empId);
          final facts = store.dayFor(
            empId,
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
              ? AttendanceClock.time(record!.checkIn, record.offsetMinutes)
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : nec.separator.withValues(alpha: 0.18),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E3B)
                                : const Color(0xFFE8EAFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            CupertinoIcons.clock_fill,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'My Attendance',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: nec.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Track your daily work hours',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: nec.textTertiary,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
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
                                    margin: const EdgeInsets.only(right: 6),
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
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                facts.status.label,
                                style: TextStyle(
                                  color: nec.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          workedDurationText,
                          style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'worked today',
                          style: TextStyle(
                            color: nec.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            color: progress >= 1.0
                                ? AppColors.success
                                : const Color(0xFF4F46E5),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: const Color(0xFF4F46E5),
                        backgroundColor: isDark
                            ? const Color(0xFF4F46E5).withValues(alpha: 0.18)
                            : const Color(0xFFE8EAFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF4F5FF),
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
                              iconBg: isDark
                                  ? const Color(0xFF1E2840)
                                  : const Color(0xFFE0E7FF),
                              iconColor: const Color(0xFF4F46E5),
                              nec: nec,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: nec.separator.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            flex: 10,
                            child: _StatColumn(
                              label: 'Check-in',
                              value: checkInStr,
                              icon: CupertinoIcons.arrow_right_square_fill,
                              iconBg: isDark
                                  ? const Color(0xFF123B2B)
                                  : const Color(0xFFD1FAE5),
                              iconColor: const Color(0xFF10B981),
                              nec: nec,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: nec.separator.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            flex: 9,
                            child: _StatColumn(
                              label: 'Overtime',
                              value: facts.overtimeMinutes > 0
                                  ? '+${facts.overtimeMinutes}m'
                                  : '0m',
                              icon: CupertinoIcons.bolt_fill,
                              iconBg: isDark
                                  ? const Color(0xFF3B2F14)
                                  : const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFF59E0B),
                              nec: nec,
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
  final Color iconBg;
  final Color iconColor;
  final NecColors nec;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.nec,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: nec.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
