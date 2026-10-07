import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../settings/data/system_settings_store.dart';
import '../../team/data/employee_store.dart';
import '../../team/domain/models/employee.dart';
import '../data/attendance_clock.dart';
import '../data/attendance_store.dart';
import '../data/attendance_export.dart';
import '../domain/models/attendance_models.dart';
import 'widgets/attendance_ui.dart';
import 'widgets/attendance_requests.dart';
import 'widgets/attendance_edit_form.dart';
import 'widgets/attendance_pickers.dart';
import 'widgets/attendance_day_detail.dart';
import '../../meals/presentation/widgets/lunch_entry.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen> {
  int _tab = 0;
  final _search = TextEditingController();
  String? _department;
  AttendanceRequestStatus? _status = AttendanceRequestStatus.pending;
  AttendanceRequestKind? _kind;
  late DateTime _date;
  late DateTime _month;
  bool _exporting = false;
  bool _showInactive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _date = AttendanceClock.today;
    _month = DateTime.utc(_date.year, _date.month);
    _search.addListener(_refresh);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _timer?.cancel();
    super.dispose();
  }

  List<Employee> get _employees => EmployeeStore.instance.staffEmployees
      .where((employee) =>
          (_showInactive || employee.status == 'Active') &&
          (_department == null ||
              employee.department.split(' · ').first == _department) &&
          ('${employee.name} ${employee.displayCode} ${employee.email}'
              .toLowerCase()
              .contains(_search.text.trim().toLowerCase())))
      .toList();

  Future<void> _export() async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final saved = await AttendanceExport.save(_month, _employees);
      if (mounted && saved) {
        NecToast.show(context, message: 'Attendance report exported');
      }
    } catch (error) {
      if (mounted) {
        attendanceError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
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
        final nec = Theme.of(context).extension<NecColors>()!;
        final store = AttendanceStore.instance;
        final actor = store.administratorId;
        if (actor == null) {
          return Scaffold(
              backgroundColor: nec.bg,
              appBar: attendanceAppBar(context, 'Attendance Admin'),
              body: const Padding(
                  padding: EdgeInsets.all(20),
                  child: AttendanceEmpty(
                      title: 'Administrator access required',
                      message:
                          'An active administrator account is needed to manage attendance.')));
        }
        final employees = _employees;
        final today = AttendanceClock.key(AttendanceClock.today);
        final todayDays = EmployeeStore.instance.staffEmployees
            .where((employee) => employee.status == 'Active')
            .map((employee) => store.dayFor(employee.id, today))
            .toList();
        final pending = store.allRequests
            .where((request) =>
                request.status == AttendanceRequestStatus.pending &&
                EmployeeStore.instance.isStaffEmployee(request.employeeId))
            .toList();
        final requests = store.allRequests
            .where((request) =>
                (_status == null || request.status == _status) &&
                (_kind == null || request.kind == _kind) &&
                employees.any((employee) => employee.id == request.employeeId))
            .toList();
        return Scaffold(
            backgroundColor: nec.bg,
            appBar: attendanceAppBar(context, 'Attendance Admin', actions: [
              IconButton(
                  tooltip: 'Attendance settings',
                  onPressed: () => context.push('/attendance/settings'),
                  icon:
                      Icon(CupertinoIcons.gear_alt, color: nec.brand, size: 22))
            ]),
            body: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<int>(
                              groupValue: _tab,
                              thumbColor: nec.surface,
                              backgroundColor:
                                  nec.separator.withValues(alpha: .2),
                              children: {
                                for (var index = 0; index < 4; index++)
                                  index: Text(
                                      [
                                        'Overview',
                                        'Staff',
                                        'Requests',
                                        'Reports'
                                      ][index],
                                      style: TextStyle(
                                          color: nec.textPrimary, fontSize: 12))
                              },
                              onValueChanged: (value) {
                                if (value != null) {
                                  setState(() => _tab = value);
                                }
                              }))),
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
                                  const SizedBox(height: 14)
                                ],
                                if (_tab == 0) ...[
                                  AttendanceCard(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(AttendanceClock.dayLabel(today),
                                            style: TextStyle(
                                                color: nec.textPrimary,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 7),
                                        Text(
                                            '${AttendanceClock.minutesTime(store.policy.startMinutes)} – ${AttendanceClock.minutesTime(store.policy.endMinutes)} · ${AttendanceClock.timezone}',
                                            style: TextStyle(
                                                color: nec.textSecondary,
                                                fontSize: 13)),
                                        const SizedBox(height: 6),
                                        Text(
                                            'Reviewer: ${EmployeeStore.instance.byId(actor)?.name ?? 'Administrator'}',
                                            style: TextStyle(
                                                color: nec.textTertiary,
                                                fontSize: 12)),
                                      ])),
                                  const SizedBox(height: 14),
                                  AttendanceMetrics(items: [
                                    (
                                      'Working now',
                                      '${todayDays.where((day) => day.record?.open == true).length}',
                                      nec.brand
                                    ),
                                    (
                                      'Attended today',
                                      '${todayDays.where((day) => day.record?.checkIn != null).length}',
                                      AppColors.success
                                    ),
                                    (
                                      'Late arrivals',
                                      '${todayDays.where((day) => day.lateMinutes > 0).length}',
                                      AppColors.warning
                                    ),
                                    (
                                      'Absent',
                                      '${todayDays.where((day) => day.status == AttendanceStatus.absent).length}',
                                      AppColors.error
                                    ),
                                    (
                                      'On leave',
                                      '${todayDays.where((day) => day.leaveDays > 0).length}',
                                      const Color(0xFF5856D6)
                                    ),
                                    (
                                      'Pending requests',
                                      '${pending.length}',
                                      const Color(0xFF30B0C7)
                                    ),
                                  ]),
                                  AttendanceHeading('Needs review',
                                      trailing: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () => setState(() {
                                                _tab = 2;
                                                _status =
                                                    AttendanceRequestStatus
                                                        .pending;
                                                _kind = null;
                                                _department = null;
                                                _showInactive = true;
                                                _search.clear();
                                              }),
                                          child: const Text('View all'))),
                                  ...pending.take(5).map((request) =>
                                      AttendanceRequestTile(
                                          request: request,
                                          actorId: actor,
                                          showEmployee: true)),
                                  if (pending.isEmpty)
                                    const AttendanceEmpty(
                                        title: 'All caught up',
                                        message:
                                            'New leave, fix, swap, and overtime requests will appear here.'),
                                  const SizedBox(height: 16),
                                  const LunchEntry(administrator: true),
                                  const AttendanceHeading('Quick actions'),
                                  AttendanceCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(children: [
                                        ListTile(
                                            leading: Icon(
                                                CupertinoIcons.person_2,
                                                color: nec.brand),
                                            title: const Text(
                                                'Manage Staff Attendance'),
                                            trailing: const Icon(
                                                CupertinoIcons.chevron_right,
                                                size: 14),
                                            onTap: () =>
                                                setState(() => _tab = 1)),
                                        Divider(
                                            height: 1, color: nec.separator),
                                        ListTile(
                                            leading: Icon(
                                                CupertinoIcons.calendar,
                                                color: nec.brand),
                                            title: const Text(
                                                'Leave Types, Holidays & Policy'),
                                            trailing: const Icon(
                                                CupertinoIcons.chevron_right,
                                                size: 14),
                                            onTap: () => context
                                                .push('/attendance/settings')),
                                      ])),
                                ] else ...[
                                  _filters(nec),
                                  const SizedBox(height: 16),
                                  if (_tab == 1) ...[
                                    AttendancePickerRow(
                                        label: 'Attendance Date',
                                        value: AttendanceClock.dayLabel(
                                            AttendanceClock.key(_date)),
                                        icon: CupertinoIcons.calendar,
                                        onTap: () async {
                                          final date = await pickAttendanceDate(
                                              context, _date);
                                          if (mounted && date != null) {
                                            setState(() => _date = DateTime.utc(
                                                date.year,
                                                date.month,
                                                date.day));
                                          }
                                        }),
                                    if (employees.isEmpty)
                                      const AttendanceEmpty(
                                          title: 'No matching staff',
                                          message:
                                              'Try a different name or department.'),
                                    ...employees.map((employee) =>
                                        _staffRow(employee, actor, nec)),
                                  ] else if (_tab == 2) ...[
                                    Row(children: [
                                      Expanded(
                                          child: CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              onPressed: () async {
                                                final value =
                                                    await chooseAttendanceOption(
                                                        context,
                                                        'Request status', [
                                                  ('all', 'All statuses'),
                                                  ...AttendanceRequestStatus
                                                      .values
                                                      .map((status) => (
                                                            status.name,
                                                            status.label
                                                          ))
                                                ]);
                                                if (mounted && value != null) {
                                                  setState(() => _status =
                                                      value == 'all'
                                                          ? null
                                                          : AttendanceRequestStatus
                                                              .values
                                                              .byName(value));
                                                }
                                              },
                                              child: Text(
                                                  _status?.label ??
                                                      'All statuses',
                                                  style: TextStyle(
                                                      color: nec.brand,
                                                      fontSize: 14)))),
                                      Expanded(
                                          child: CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              onPressed: () async {
                                                final value =
                                                    await chooseAttendanceOption(
                                                        context,
                                                        'Request type', [
                                                  ('all', 'All request types'),
                                                  ...AttendanceRequestKind
                                                      .values
                                                      .map((kind) => (
                                                            kind.name,
                                                            kind.label
                                                          ))
                                                ]);
                                                if (mounted && value != null) {
                                                  setState(() => _kind =
                                                      value == 'all'
                                                          ? null
                                                          : AttendanceRequestKind
                                                              .values
                                                              .byName(value));
                                                }
                                              },
                                              child: Text(
                                                  _kind?.label ?? 'All types',
                                                  style: TextStyle(
                                                      color: nec.brand,
                                                      fontSize: 14))))
                                    ]),
                                    ...requests.map((request) =>
                                        AttendanceRequestTile(
                                            request: request,
                                            actorId: actor,
                                            showEmployee: true)),
                                    if (requests.isEmpty)
                                      const AttendanceEmpty(
                                          title: 'No matching requests',
                                          message:
                                              'Change the filters to see request history.'),
                                  ] else ...[
                                    Row(children: [
                                      IconButton(
                                          tooltip: 'Previous month',
                                          icon: Icon(
                                              CupertinoIcons.chevron_left,
                                              color: nec.brand,
                                              size: 19),
                                          onPressed: () => setState(() =>
                                              _month = DateTime.utc(_month.year,
                                                  _month.month - 1))),
                                      Expanded(
                                          child: Text(
                                              DateFormat('MMMM yyyy')
                                                  .format(_month),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: nec.textPrimary,
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      IconButton(
                                          tooltip: 'Next month',
                                          icon: Icon(
                                              CupertinoIcons.chevron_right,
                                              color: nec.brand,
                                              size: 19),
                                          onPressed: () => setState(() =>
                                              _month = DateTime.utc(_month.year,
                                                  _month.month + 1)))
                                    ]),
                                    const SizedBox(height: 8),
                                    NecButton(
                                        label: 'Export Monthly CSV',
                                        icon: const Icon(
                                            CupertinoIcons.arrow_down_doc,
                                            size: 19,
                                            color: Colors.white),
                                        fullWidth: true,
                                        loading: _exporting,
                                        onPressed:
                                            employees.isEmpty ? null : _export),
                                    const SizedBox(height: 18),
                                    ...employees.map((employee) =>
                                        _reportRow(employee, nec)),
                                    if (employees.isEmpty)
                                      const AttendanceEmpty(
                                          title: 'No staff to report',
                                          message:
                                              'Change your staff filters to generate a report.'),
                                  ],
                                ],
                              ]))),
                ])));
      });

  Widget _filters(NecColors nec) => Column(children: [
        CupertinoSearchTextField(
            controller: _search,
            placeholder: 'Search staff, ID, or email',
            style: TextStyle(color: nec.textPrimary),
            backgroundColor: nec.surface),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final departments = EmployeeStore.instance.staffEmployees
                        .map((employee) =>
                            employee.department.split(' · ').first)
                        .toSet()
                        .toList()
                      ..sort();
                    final value = await chooseAttendanceOption(
                        context, 'Department', [
                      ('all', 'All departments'),
                      ...departments.map((item) => (item, item))
                    ]);
                    if (mounted && value != null) {
                      setState(
                          () => _department = value == 'all' ? null : value);
                    }
                  },
                  child: Text(_department ?? 'All departments',
                      style: TextStyle(color: nec.brand, fontSize: 13)))),
          Text('Inactive',
              style: TextStyle(color: nec.textTertiary, fontSize: 12)),
          const SizedBox(width: 8),
          CupertinoSwitch(
              value: _showInactive,
              onChanged: (value) => setState(() => _showInactive = value))
        ]),
      ]);

  Widget _staffRow(Employee employee, String actor, NecColors nec) {
    final day = AttendanceStore.instance
        .dayFor(employee.id, AttendanceClock.key(_date));
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: NecAvatar(
                    initials: employee.avatarInitials,
                    photoBase64: employee.photoBase64,
                    size: 38),
                title: Text(employee.name,
                    style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                          '${AttendanceClock.time(day.record?.checkIn, day.record?.offsetMinutes)} – ${AttendanceClock.time(day.record?.checkOut, day.record?.offsetMinutes)}',
                          style:
                              TextStyle(color: nec.textTertiary, fontSize: 12)),
                      const SizedBox(height: 6),
                      AttendanceBadge(
                          day.status.label, attendanceColor(day.status))
                    ]),
                trailing: IconButton(
                    tooltip: 'Manage attendance',
                    icon: Icon(CupertinoIcons.square_pencil,
                        color: nec.brand, size: 20),
                    onPressed: _date.isAfter(AttendanceClock.today)
                        ? null
                        : () => showAttendanceSheet(
                            context,
                            AttendanceEditForm(
                                employeeId: employee.id,
                                day: AttendanceClock.key(_date),
                                actorId: actor))),
                onTap: () => showAttendanceSheet(
                    context,
                    AttendanceDayDetail(
                        employeeId: employee.id,
                        day: AttendanceClock.key(_date),
                        actorId: actor)))));
  }

  Widget _reportRow(Employee employee, NecColors nec) {
    final days = AttendanceStore.instance.monthFor(employee.id, _month);
    final present = days.where((day) => day.record?.checkIn != null).length;
    final absent = days
        .where((day) => day.status == AttendanceStatus.absent)
        .fold(0.0, (sum, day) => sum + 1 - day.leaveDays);
    final leave = days.fold(0.0, (sum, day) => sum + day.leaveDays);
    final worked = days.fold(0, (sum, day) => sum + day.workedMinutes);
    final extra = days.fold(0, (sum, day) => sum + day.overtimeMinutes);
    final approved =
        days.fold(0, (sum, day) => sum + day.approvedOvertimeMinutes);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AttendanceCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            NecAvatar(
                initials: employee.avatarInitials,
                photoBase64: employee.photoBase64,
                size: 34),
            const SizedBox(width: 10),
            Expanded(
                child: Text(employee.name,
                    style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600))),
            IconButton(
                tooltip: 'View staff calendar',
                onPressed: () => context.push(
                    '/attendance/employee/${employee.id}?month=${AttendanceClock.key(_month)}'),
                icon: Icon(CupertinoIcons.chevron_right,
                    color: nec.textTertiary, size: 15))
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 9, children: [
            Text('$present attended',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
            Text('${days.where((day) => day.lateMinutes > 0).length} late',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
            Text('$absent absent',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
            Text('$leave leave',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
            Text(
                '${days.where((day) => day.status == AttendanceStatus.swappedOff).length} swapped off',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
            Text(
                '${days.where((day) => day.record?.checkIn != null && day.record?.wasWorkingDay == false && !AttendanceStore.instance.swappedWork(employee.id, day.day)).length} off days worked',
                style: TextStyle(color: nec.textSecondary, fontSize: 12)),
          ]),
          Divider(height: 26, color: nec.separator),
          Text(
              '${AttendanceClock.duration(worked)} worked · ${AttendanceClock.duration(extra)} extra',
              style: TextStyle(color: nec.textSecondary, fontSize: 12)),
          const SizedBox(height: 5),
          Text('${AttendanceClock.duration(approved)} approved overtime',
              style: TextStyle(
                  color: nec.brand, fontSize: 13, fontWeight: FontWeight.w600)),
        ])));
  }
}
