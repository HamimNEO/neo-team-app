import 'lunch_settings_sheet.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../attendance/data/attendance_clock.dart';
import '../../attendance/data/attendance_store.dart';
import '../../attendance/presentation/widgets/attendance_pickers.dart';
import '../../attendance/presentation/widgets/attendance_ui.dart';
import '../../settings/data/system_settings_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../data/meal_store.dart';
import '../domain/models/lunch_preference.dart';

class _LunchArtPainter extends CustomPainter {
  final bool isDark;

  _LunchArtPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final auraColor =
        isDark ? const Color(0xFF1A2A48) : const Color(0xFFEBF5FF);
    const accentColor = Color(0xFF3B82F6);

    final auraPaint = Paint()
      ..color = auraColor.withValues(alpha: isDark ? 0.5 : 0.8)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width * 0.65, size.height * 0.60);
    final radius = size.height * 0.70;
    canvas.drawCircle(center, radius, auraPaint);

    final sparkPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.7 : 0.8)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.25),
      Offset(size.width * 0.24, size.height * 0.15),
      sparkPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.18),
      Offset(size.width * 0.40, size.height * 0.05),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LunchArtPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class MealScreen extends StatefulWidget {
  final bool administrator;

  const MealScreen({super.key, this.administrator = false});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  bool get _administrator =>
      widget.administrator || DemoSession.instance.isAdmin;
  late String _day;
  final _saving = <String>{};
  final _search = TextEditingController();
  Timer? _timer;
  final _mealNote = TextEditingController();
  String? _mealPreference;

  @override
  void initState() {
    super.initState();
    _day = AttendanceClock.key(AttendanceClock.today);
    _search.addListener(_refresh);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    _loadDay();
  }

  void _selectDay(String newDay) {
    setState(() => _day = newDay);
    _mealPreference = null;
    _mealNote.clear();
    _loadDay();
  }

  Future<void> _loadDay() async {
    final day = _day;
    await MealStore.instance.syncRemote(day: day);
    if (!mounted || day != _day) return;
    final pref =
        MealStore.instance.preferenceFor(EmployeeStore.currentEmployeeId, day);
    _mealNote.text = pref?.note ?? '';
    _mealPreference = pref?.mealPreference;
    await MealStore.instance.loadMonthly(day.substring(0, 7));
    _refresh();
  }

  Future<void> _saveMealOptions() async {
    final own = EmployeeStore.instance.currentEmployee;
    setState(() => _saving.add(own.id));
    try {
      await MealStore.instance.setLunch(
          employeeId: own.id,
          day: _day,
          takeLunch:
              MealStore.instance.preferenceFor(own.id, _day)?.takeLunch ?? true,
          actorId: own.id,
          mealPreference: _mealPreference ?? 'regular',
          note: _mealNote.text.trim());
      if (mounted) NecToast.show(context, message: 'Meal preference saved');
    } catch (e) {
      if (mounted) attendanceError(context, e);
    } finally {
      if (mounted) setState(() => _saving.remove(own.id));
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    _mealNote.dispose();
    super.dispose();
  }

  Future<void> _change(Employee employee, bool takeLunch) async {
    if (_saving.contains(employee.id)) {
      return;
    }
    final actor = _administrator
        ? AttendanceStore.instance.administratorId
        : EmployeeStore.currentEmployeeId;
    if (actor == null) {
      return;
    }
    setState(() => _saving.add(employee.id));
    try {
      await MealStore.instance.setLunch(
          employeeId: employee.id,
          day: _day,
          takeLunch: takeLunch,
          actorId: actor);
      if (mounted) {
        NecToast.show(context,
            message:
                takeLunch ? 'Office lunch restored' : 'Office lunch skipped');
      }
    } catch (error) {
      if (mounted) {
        attendanceError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving.remove(employee.id));
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await pickAttendanceDate(context, AttendanceClock.date(_day),
        first: _administrator
            ? AttendanceClock.date(
                AttendanceStore.instance.policy.trackingStart)
            : AttendanceClock.today);
    if (mounted && date != null) {
      _selectDay(AttendanceClock.key(date));
    }
  }

  Color _color(LunchStatus status, NecColors nec) => switch (status) {
        LunchStatus.receiving => CupertinoColors.systemGreen,
        LunchStatus.skipped => CupertinoColors.systemOrange,
        _ => nec.textTertiary,
      };

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
          final store = MealStore.instance;
          final actor = AttendanceStore.instance.administratorId;
          final employees = EmployeeStore.instance.staffEmployees
              .where((employee) => employee.status == 'Active')
              .toList();
          final error = store.loadError ??
              store.remoteError ??
              AttendanceStore.instance.loadError;
          if (!DemoSession.instance.signedIn) return const SizedBox.shrink();
          final own = EmployeeStore.instance.currentEmployee;
          final history =
              store.historyFor(_administrator ? null : own.id, _day);
          final needed = employees
              .where((employee) =>
                  store.statusFor(employee.id, _day) == LunchStatus.receiving)
              .length;
          final skipped = employees
              .where((employee) =>
                  store.statusFor(employee.id, _day) == LunchStatus.skipped)
              .length;
          final offOrLeave = employees.where((employee) {
            final s = store.statusFor(employee.id, _day);
            return s == LunchStatus.offDay || s == LunchStatus.leave;
          }).length;

          return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(
                context, _administrator ? 'Lunch Management' : 'My Lunch',
                actions: _administrator
                    ? [
                        IconButton(
                            tooltip: 'Lunch settings',
                            icon: const Icon(CupertinoIcons.gear_alt),
                            onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => const LunchSettingsSheet()))
                      ]
                    : null),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadDay();
                  await store.loadMonthly(_day.substring(0, 7), force: true);
                },
                color: nec.brand,
                backgroundColor: nec.surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_administrator && actor == null)
                        const AttendanceEmpty(
                            title: 'Administrator access required',
                            message:
                                'An active administrator is required to manage office lunches.')
                      else ...[
                        Container(
                          decoration: BoxDecoration(
                            color: nec.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : nec.separator.withValues(alpha: 0.18),
                              width: 0.7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.20 : 0.035),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E2840)
                                      : const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  CupertinoIcons.cart_fill,
                                  color: Color(0xFF007AFF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E3A5F)
                                            : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'EMPLOYEE MEAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF60A5FA)
                                              : const Color(0xFF2563EB),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Office Lunch',
                                      style: TextStyle(
                                        color: nec.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lunch only · included on working days',
                                      style: TextStyle(
                                        color: nec.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 80,
                                height: 60,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter:
                                            _LunchArtPainter(isDark: isDark),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Transform.rotate(
                                        angle: 0.35,
                                        child: Image.asset(
                                          'assets/others/lunch_employee.png',
                                          height: 54,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F2B48)
                                    : const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.calendar,
                                  size: 16, color: Color(0xFF007AFF)),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lunch date',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: nec.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Select the date for your lunch preference',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nec.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _saving.isEmpty ? _pickDate : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.calendar,
                                    size: 18, color: Color(0xFF007AFF)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AttendanceClock.dayLabel(_day),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(CupertinoIcons.chevron_down,
                                    size: 16, color: nec.textTertiary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var offset = 0; offset < 2; offset++) ...[
                              if (offset > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateSegmentButton(
                                  label: offset == 0 ? 'Today' : 'Tomorrow',
                                  isSelected: _day ==
                                      AttendanceClock.key(AttendanceClock.today
                                          .add(Duration(days: offset))),
                                  onTap: _saving.isEmpty
                                      ? () => _selectDay(AttendanceClock.key(
                                          AttendanceClock.today
                                              .add(Duration(days: offset))))
                                      : null,
                                  isDark: isDark,
                                  nec: nec,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Text(error,
                              style: const TextStyle(
                                  color: CupertinoColors.systemRed)),
                        ],
                        const SizedBox(height: 20),
                        if (_administrator) ...[
                          AttendanceMetrics(items: [
                            (
                              'Lunches needed',
                              '$needed',
                              CupertinoColors.systemGreen
                            ),
                            (
                              'Skipping lunch',
                              '$skipped',
                              CupertinoColors.systemOrange
                            ),
                            ('Off / on leave', '$offOrLeave', nec.textTertiary),
                          ]),
                          const SizedBox(height: 12),
                          Text(
                              'Counts include all active staff. Weekly off days, holidays and swapped off days are excluded unless attendance is recorded. Approved full-day leave is also excluded.',
                              style: TextStyle(
                                  color: nec.textSecondary,
                                  fontSize: 12,
                                  height: 1.5)),
                          const AttendanceHeading('Staff lunches'),
                          CupertinoSearchTextField(
                              controller: _search,
                              placeholder: 'Search staff or employee ID',
                              style: TextStyle(color: nec.textPrimary),
                              backgroundColor: nec.surface),
                          const SizedBox(height: 14),
                          ...employees
                              .where((employee) =>
                                  '${employee.name} ${employee.displayCode}'
                                      .toLowerCase()
                                      .contains(
                                          _search.text.trim().toLowerCase()))
                              .map((employee) =>
                                  _employeeRow(employee, nec, error == null)),
                          if (employees.isEmpty)
                            const AttendanceEmpty(
                                title: 'No active staff',
                                message:
                                    'Active employee lunches will appear here.'),
                          const SizedBox(height: 12),
                          Text(
                              'Admin can update today’s or future lunches. Past dates are read-only.',
                              style: TextStyle(
                                  color: nec.textTertiary, fontSize: 12)),
                        ] else ...[
                          _buildEmployeeLunchToggle(
                            employee: own,
                            nec: nec,
                            isDark: isDark,
                            ready: error == null,
                          ),
                          const SizedBox(height: 18),
                          const SizedBox(height: 16),
                          AttendanceCard(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                DropdownButtonFormField<String>(
                                    initialValue: _mealPreference ??
                                        store
                                            .preferenceFor(own.id, _day)
                                            ?.mealPreference ??
                                        'regular',
                                    decoration: const InputDecoration(
                                        labelText: 'Meal preference'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'regular',
                                          child: Text('Regular')),
                                      DropdownMenuItem(
                                          value: 'veg',
                                          child: Text('Vegetarian'))
                                    ],
                                    onChanged: _saving.contains(own.id) ||
                                            !store.canChange(_day,
                                                administrator: false)
                                        ? null
                                        : (v) => setState(
                                            () => _mealPreference = v)),
                                TextField(
                                    controller: _mealNote,
                                    maxLines: 2,
                                    enabled: store.canChange(_day,
                                            administrator: false) &&
                                        !_saving.contains(own.id),
                                    decoration: const InputDecoration(
                                        labelText: 'Lunch note (optional)')),
                                const SizedBox(height: 8),
                                Text(
                                    'Same-day cutoff: ${store.policy['cutoff_time'] ?? 'Not available'} · Asia/Dhaka',
                                    style: TextStyle(
                                        color: nec.textSecondary,
                                        fontSize: 12)),
                                TextButton(
                                    onPressed: _saving.contains(own.id) ||
                                            !store.canChange(_day,
                                                administrator: false)
                                        ? null
                                        : _saveMealOptions,
                                    child: const Text('Save meal preference')),
                              ])),
                          const AttendanceHeading('Monthly Lunch Summary'),
                          if (store.monthlyError != null)
                            Text(store.monthlyError!,
                                style: const TextStyle(color: Colors.red)),
                          if (store.monthlySummary.isNotEmpty)
                            AttendanceCard(
                                child: Column(children: [
                              Text('${store.monthlySummary['month'] ?? ''}',
                                  style: TextStyle(color: nec.textSecondary)),
                              for (final field in const {
                                'selected_days': 'Selected meals',
                                'skipped_days': 'Skipped meals',
                                'subsidy': 'Company subsidy',
                                'employee_charge': 'Employee charge'
                              }.entries)
                                if (store.monthlySummary[field.key] != null)
                                  ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(field.value),
                                      trailing: Text(
                                          '${store.monthlySummary[field.key]}')),
                            ])),
                          const AttendanceHeading('Next 7 days'),
                          AttendanceCard(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                for (var index = 1; index <= 7; index++)
                                  _upcomingRow(index, nec),
                              ])),
                        ],
                        const AttendanceHeading('Changes for this date'),
                        ...history.map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AttendanceCard(
                                child: Text(
                                    '${_administrator ? '${EmployeeStore.instance.byId(change.employeeId)?.name ?? 'Employee'} · ' : ''}${change.takeLunch ? 'Lunch restored' : 'Lunch skipped'}\nChanged by ${EmployeeStore.instance.byId(change.actorId)?.name ?? 'Employee'} · ${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(change.updatedAt)))} · ${AttendanceClock.time(change.updatedAt)}',
                                    style: TextStyle(
                                        color: nec.textSecondary,
                                        fontSize: 12,
                                        height: 1.5))))),
                        if (history.isEmpty)
                          Text('No lunch changes recorded for this date.',
                              style: TextStyle(
                                  color: nec.textTertiary, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _buildDateSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool isDark,
    required NecColors nec,
  }) {
    const activeBg = Color(0xFF00C7BE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? activeBg
              : (isDark ? Colors.white.withValues(alpha: 0.04) : nec.surface),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : nec.separator.withValues(alpha: 0.2),
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.calendar,
              size: 18,
              color: isSelected ? Colors.white : nec.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : nec.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeLunchToggle({
    required Employee employee,
    required NecColors nec,
    required bool isDark,
    required bool ready,
  }) {
    final store = MealStore.instance;
    final status = store.statusFor(employee.id, _day);
    final busy = _saving.contains(employee.id);
    final enabled = ready &&
        !busy &&
        status.available &&
        store.canChange(_day, administrator: _administrator);
    final isTaking = status == LunchStatus.receiving;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : nec.separator.withValues(alpha: 0.18),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF123B2B)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.tray_fill,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take office lunch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: nec.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Let the team know if you’ll be having lunch.',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isTaking
                            ? (isDark
                                ? const Color(0xFF0F3A22)
                                : const Color(0xFFD1FAE5))
                            : (isDark
                                ? const Color(0xFF3B2F14)
                                : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTaking
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.xmark_circle_fill,
                            size: 12,
                            color: isTaking
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isTaking
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (busy)
                const CupertinoActivityIndicator()
              else
                CupertinoSwitch(
                  activeTrackColor: const Color(0xFF00C7BE),
                  value: isTaking,
                  onChanged:
                      enabled ? (value) => _change(employee, value) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2138) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle_fill,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Changes apply to upcoming lunches. Update your choice before the day begins (${AttendanceClock.timezone}). For same-day changes, contact your admin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _employeeRow(Employee employee, NecColors nec, bool ready) {
    final store = MealStore.instance;
    final status = store.statusFor(employee.id, _day);
    final busy = _saving.contains(employee.id);
    final enabled = ready &&
        !busy &&
        status.available &&
        store.canChange(_day, administrator: _administrator);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AttendanceCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (_administrator) ...[
                NecAvatar(
                    initials: employee.avatarInitials,
                    photoBase64: employee.photoBase64,
                    photoUrl: employee.photoUrl,
                    assetPath: employee.avatarAsset,
                    size: 36),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_administrator ? employee.name : 'Take Office Lunch',
                        style: TextStyle(
                            color: nec.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    AttendanceBadge(status.label, _color(status, nec)),
                    if (!status.available) ...[
                      const SizedBox(height: 6),
                      Text('No lunch scheduled',
                          style:
                              TextStyle(color: nec.textTertiary, fontSize: 12))
                    ],
                  ])),
              const SizedBox(width: 12),
              if (busy)
                const CupertinoActivityIndicator()
              else
                CupertinoSwitch(
                    value: status == LunchStatus.receiving,
                    onChanged:
                        enabled ? (value) => _change(employee, value) : null),
            ])));
  }

  Widget _upcomingRow(int index, NecColors nec) {
    final day =
        AttendanceClock.key(AttendanceClock.today.add(Duration(days: index)));
    final status =
        MealStore.instance.statusFor(EmployeeStore.currentEmployeeId, day);
    return Column(children: [
      if (index > 1) Divider(height: 1, color: nec.separator, indent: 16),
      ListTile(
          title: Text(AttendanceClock.dayLabel(day),
              style: TextStyle(color: nec.textPrimary, fontSize: 14)),
          trailing: AttendanceBadge(status.label, _color(status, nec)),
          onTap: _saving.isEmpty ? () => _selectDay(day) : null),
    ]);
  }
}
