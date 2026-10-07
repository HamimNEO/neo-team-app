import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import 'attendance_admin_screen.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../settings/data/system_settings_store.dart';
import '../../team/data/employee_store.dart';
import '../data/attendance_clock.dart';
import '../data/attendance_store.dart';
import '../domain/models/attendance_models.dart';
import 'widgets/attendance_ui.dart';
import 'widgets/attendance_today_card.dart';
import 'widgets/attendance_month_view.dart';
import 'widgets/attendance_request_form.dart';
import 'widgets/attendance_requests.dart';
import 'widgets/attendance_pickers.dart';
import 'widgets/attendance_day_detail.dart';
import '../../meals/presentation/widgets/lunch_entry.dart';

class AttendanceScreen extends StatefulWidget {
  final String? employeeId;
  final DateTime? initialMonth;

  const AttendanceScreen({super.key, this.employeeId, this.initialMonth});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _tab = 0;
  AttendanceRequestKind? _kind;
  Timer? _refresh;

  String get _employeeId =>
      widget.employeeId ?? EmployeeStore.currentEmployeeId;

  bool get _own =>
      widget.employeeId == null ||
      widget.employeeId == EmployeeStore.currentEmployeeId;

  @override
  void initState() {
    super.initState();
    if (!_own || widget.initialMonth != null) {
      _tab = 1;
    }
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _request(AttendanceRequestKind kind) async {
    if (!_own || DemoSession.instance.isAdmin) return;
    final saved = await showAttendanceSheet<bool>(
        context,
        AttendanceRequestForm(
            employeeId: _employeeId,
            day: kind == AttendanceRequestKind.correction
                ? AttendanceStore.instance.activeRecord(_employeeId)?.day
                : null,
            kind: kind));
    if (mounted && saved == true) {
      setState(() => _tab = 2);
      NecToast.show(context, message: '${kind.label} request sent');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([
        AttendanceStore.instance,
        EmployeeStore.instance,
        SystemSettingsStore.instance
      ]),
      builder: (context, _) {
        if (DemoSession.instance.isAdmin &&
            (_own || !EmployeeStore.instance.isStaffEmployee(_employeeId))) {
          return const AttendanceAdminScreen();
        }
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = AttendanceStore.instance;
        final employee = EmployeeStore.instance.byId(_employeeId);
        final actor = _own ? null : store.administratorId;
        if (employee == null) {
          return Scaffold(
              appBar: attendanceAppBar(context, 'Attendance'),
              body: const Center(child: Text('Employee not found.')));
        }
        final requests = store
            .requestsFor(_employeeId)
            .where((request) => _kind == null || request.kind == _kind)
            .toList();
        return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(
                context, _own ? 'My Attendance' : 'Employee Attendance'),
            body: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(employee.name,
                                  style: TextStyle(
                                      color: nec.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  '${employee.displayCode} · ${employee.department.split(' · ').first}',
                                  style: TextStyle(
                                      color: nec.textTertiary, fontSize: 12)),
                            ])),
                        if (_own && !DemoSession.instance.isAdmin)
                          IconButton(
                              tooltip: 'New attendance request',
                              icon: Icon(CupertinoIcons.add_circled,
                                  color: nec.brand),
                              onPressed: () async {
                                final kind = await chooseAttendanceOption(
                                    context,
                                    'New request',
                                    AttendanceRequestKind.values
                                        .map((kind) => (kind.name, kind.label))
                                        .toList());
                                if (mounted && kind != null) {
                                  await _request(AttendanceRequestKind.values
                                      .byName(kind));
                                }
                              }),
                      ])),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<int>(
                              groupValue: _tab,
                              thumbColor: nec.surface,
                              backgroundColor:
                                  nec.separator.withValues(alpha: .2),
                              children: {
                                0: Text('Today',
                                    style: TextStyle(
                                        color: nec.textPrimary, fontSize: 13)),
                                1: Text('Monthly',
                                    style: TextStyle(
                                        color: nec.textPrimary, fontSize: 13)),
                                2: Text('Requests',
                                    style: TextStyle(
                                        color: nec.textPrimary, fontSize: 13))
                              },
                              onValueChanged: (value) {
                                if (value != null) {
                                  setState(() => _tab = value);
                                }
                              }))),
                  const SizedBox(height: 16),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (store.loadError != null) ...[
                                  AttendanceCard(
                                      child: Text(store.loadError!,
                                          style: const TextStyle(
                                              color:
                                                  CupertinoColors.systemRed))),
                                  const SizedBox(height: 16)
                                ],
                                if (_tab == 0) ...[
                                  if (_own)
                                    AttendanceTodayCard(employeeId: _employeeId)
                                  else
                                    AttendanceValues(rows: [
                                      (
                                        'Today',
                                        store
                                            .dayFor(
                                                _employeeId,
                                                AttendanceClock.key(
                                                    AttendanceClock.today))
                                            .status
                                            .label
                                      ),
                                      (
                                        'Shift',
                                        '${AttendanceClock.minutesTime(store.policy.startMinutes)} – ${AttendanceClock.minutesTime(store.policy.endMinutes)}'
                                      ),
                                      ('Timezone', AttendanceClock.timezone),
                                    ]),
                                  if (_own) ...[
                                    const SizedBox(height: 18),
                                    const LunchEntry(),
                                  ],
                                  AttendanceHeading(DemoSession.instance.isAdmin
                                      ? 'Manage attendance'
                                      : 'Requests & actions'),
                                  _actions(nec),
                                  const AttendanceHeading('Leave balances'),
                                  ...store.policy.leaveTypes
                                      .where((type) => type.enabled)
                                      .map((type) {
                                    final balance = store.balance(_employeeId,
                                        type, AttendanceClock.today.year);
                                    return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: AttendanceCard(
                                            child: Row(children: [
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(type.name,
                                                    style: TextStyle(
                                                        color: nec.textPrimary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 5),
                                                Text(
                                                    '${balance.used} used · ${balance.pending} pending · ${type.paid ? 'Paid' : 'Unpaid'}',
                                                    style: TextStyle(
                                                        color: nec.textTertiary,
                                                        fontSize: 12))
                                              ])),
                                          const SizedBox(width: 12),
                                          Text(
                                              balance.remaining == null
                                                  ? 'Unlimited'
                                                  : '${balance.remaining} left',
                                              style: TextStyle(
                                                  color: nec.brand,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600)),
                                        ])));
                                  }),
                                  const AttendanceHeading('Latest requests'),
                                  ...store.requestsFor(_employeeId).take(3).map(
                                      (request) => AttendanceRequestTile(
                                          request: request, actorId: actor)),
                                  if (store.requestsFor(_employeeId).isEmpty)
                                    const AttendanceEmpty(
                                        title: 'No requests yet',
                                        message:
                                            'Leave, attendance fixes, off-day swaps, and overtime approvals will appear here.'),
                                ] else if (_tab == 1)
                                  AttendanceMonthView(
                                      employeeId: _employeeId,
                                      actorId: actor,
                                      initialMonth: widget.initialMonth)
                                else ...[
                                  Row(children: [
                                    Expanded(
                                        child: Text('Request history',
                                            style: TextStyle(
                                                color: nec.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600))),
                                    CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () async {
                                          final kind =
                                              await chooseAttendanceOption(
                                                  context, 'Filter requests', [
                                            ('all', 'All requests'),
                                            ...AttendanceRequestKind.values.map(
                                                (kind) =>
                                                    (kind.name, kind.label))
                                          ]);
                                          if (mounted && kind != null) {
                                            setState(() => _kind = kind == 'all'
                                                ? null
                                                : AttendanceRequestKind.values
                                                    .byName(kind));
                                          }
                                        },
                                        child: Icon(
                                            CupertinoIcons
                                                .line_horizontal_3_decrease,
                                            color: nec.brand,
                                            size: 22))
                                  ]),
                                  const SizedBox(height: 12),
                                  if (_kind != null)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: AttendanceBadge(
                                            _kind!.label, nec.brand)),
                                  ...requests.map((request) =>
                                      AttendanceRequestTile(
                                          request: request, actorId: actor)),
                                  if (requests.isEmpty)
                                    const AttendanceEmpty(
                                        title: 'No matching requests',
                                        message:
                                            'Your submitted requests and administrator decisions will appear here.'),
                                ],
                              ]))),
                ])));
      });

  Widget _actions(NecColors nec) => AttendanceCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        if (_own && !DemoSession.instance.isAdmin)
          for (var index = 0;
              index < AttendanceRequestKind.values.length;
              index++) ...[
            if (index > 0) Divider(height: 1, color: nec.separator, indent: 16),
            ListTile(
                leading: Icon(
                    [
                      CupertinoIcons.calendar_badge_plus,
                      CupertinoIcons.square_pencil,
                      CupertinoIcons.arrow_2_squarepath,
                      CupertinoIcons.clock
                    ][index],
                    color: nec.brand,
                    size: 22),
                title: Text(
                    [
                      'Request Leave',
                      'Fix Attendance',
                      'Swap an Off Day',
                      'Request Overtime'
                    ][index],
                    style: TextStyle(color: nec.textPrimary, fontSize: 15)),
                trailing: Icon(CupertinoIcons.chevron_right,
                    color: nec.textTertiary, size: 14),
                onTap: _own || AttendanceStore.instance.administratorId != null
                    ? () => _request(AttendanceRequestKind.values[index])
                    : null),
          ],
        if (!_own && AttendanceStore.instance.administratorId != null) ...[
          Divider(height: 1, color: nec.separator, indent: 16),
          ListTile(
              leading:
                  Icon(CupertinoIcons.slider_horizontal_3, color: nec.brand),
              title: const Text('Manage Today'),
              onTap: () => showAttendanceSheet(
                  context,
                  AttendanceDayDetail(
                      employeeId: _employeeId,
                      day: AttendanceClock.key(AttendanceClock.today),
                      actorId: AttendanceStore.instance.administratorId))),
        ],
      ]));
}
