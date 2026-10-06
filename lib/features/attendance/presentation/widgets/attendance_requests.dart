import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../team/data/employee_store.dart';
import '../../data/attendance_clock.dart';
import '../../data/attendance_store.dart';
import '../../domain/models/attendance_models.dart';
import 'attendance_ui.dart';

String attendanceRequestTitle(AttendanceRequest request) =>
    switch (request.kind) {
      AttendanceRequestKind.leave => request.typeName,
      AttendanceRequestKind.correction => 'Attendance correction',
      AttendanceRequestKind.offDaySwap => 'Off-day swap',
      AttendanceRequestKind.overtime =>
        '${AttendanceClock.duration(request.overtimeMinutes)} overtime',
    };

String attendanceRequestPeriod(AttendanceRequest request) => request.day ==
        request.endDay
    ? AttendanceClock.dayLabel(request.day)
    : '${AttendanceClock.dayLabel(request.day)} → ${AttendanceClock.dayLabel(request.endDay)}';

class AttendanceRequestTile extends StatelessWidget {
  final AttendanceRequest request;
  final String? actorId;
  final bool showEmployee;

  const AttendanceRequestTile(
      {super.key,
      required this.request,
      this.actorId,
      this.showEmployee = false});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final employee = EmployeeStore.instance.byId(request.employeeId);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: () => showAttendanceSheet(
                    context,
                    AttendanceRequestDetail(
                        requestId: request.id, actorId: actorId)),
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showEmployee) ...[
                            NecAvatar(
                                initials: employee?.avatarInitials,
                                photoBase64: employee?.photoBase64,
                                size: 36),
                            const SizedBox(width: 12)
                          ],
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                if (showEmployee) ...[
                                  Text(employee?.name ?? 'Employee',
                                      style: TextStyle(
                                          color: nec.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 4)
                                ],
                                Text(attendanceRequestTitle(request),
                                    style: TextStyle(
                                        color: nec.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 5),
                                Text(attendanceRequestPeriod(request),
                                    style: TextStyle(
                                        color: nec.textSecondary,
                                        fontSize: 12)),
                                if (request.kind ==
                                    AttendanceRequestKind.leave) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                      '${request.leaveDays} working days${request.halfDayPart.isEmpty ? '' : ' · ${request.halfDayPart}'}',
                                      style: TextStyle(
                                          color: nec.textTertiary,
                                          fontSize: 12))
                                ],
                              ])),
                          const SizedBox(width: 8),
                          AttendanceBadge(request.status.label,
                              requestColor(request.status)),
                        ])))));
  }
}

class AttendanceRequestDetail extends StatefulWidget {
  final String requestId;
  final String? actorId;

  const AttendanceRequestDetail(
      {super.key, required this.requestId, this.actorId});

  @override
  State<AttendanceRequestDetail> createState() =>
      _AttendanceRequestDetailState();
}

class _AttendanceRequestDetailState extends State<AttendanceRequestDetail> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _act({bool? approve, bool revoke = false}) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (revoke) {
        await AttendanceStore.instance.revokeOvertime(widget.requestId,
            actorId: widget.actorId!, note: _note.text);
      } else if (approve == null) {
        await AttendanceStore.instance.cancelRequest(widget.requestId,
            actorId: widget.actorId ?? EmployeeStore.currentEmployeeId);
      } else {
        await AttendanceStore.instance.reviewRequest(widget.requestId,
            actorId: widget.actorId!, approve: approve, note: _note.text);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is FormatException
            ? error.message
            : 'Unable to update this request.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: AttendanceStore.instance,
      builder: (context, _) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final request = AttendanceStore.instance.requestById(widget.requestId);
        if (request == null) {
          return const AttendanceSheetBody(title: 'Request', children: [
            AttendanceEmpty(
                title: 'Request unavailable',
                message: 'This request could not be found.')
          ]);
        }
        final employee = EmployeeStore.instance.byId(request.employeeId);
        final original = request.originalRecord == null
            ? null
            : AttendanceRecord.fromJson(request.originalRecord!);
        final canReview = widget.actorId != null &&
            AttendanceStore.instance.isAdministrator(widget.actorId!) &&
            request.status == AttendanceRequestStatus.pending;
        final canCancel = (widget.actorId != null ||
                request.employeeId == EmployeeStore.currentEmployeeId) &&
            AttendanceStore.instance.canCancel(request);
        final canRevoke = widget.actorId != null &&
            AttendanceStore.instance.isAdministrator(widget.actorId!) &&
            request.kind == AttendanceRequestKind.overtime &&
            request.status == AttendanceRequestStatus.approved;
        final history = AttendanceStore.instance.state.events
            .where((event) => event.requestAfter?['id'] == request.id)
            .toList()
            .reversed;
        return PopScope(
            canPop: !_busy,
            child: AbsorbPointer(
                absorbing: _busy,
                child: AttendanceSheetBody(title: 'Request Detail', children: [
                  Row(children: [
                    Expanded(
                        child: Text(attendanceRequestTitle(request),
                            style: TextStyle(
                                color: nec.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w700))),
                    AttendanceBadge(
                        request.status.label, requestColor(request.status))
                  ]),
                  const SizedBox(height: 20),
                  AttendanceValues(rows: [
                    ('Employee', employee?.name ?? 'Employee'),
                    ('Request Type', request.kind.label),
                    ('Period', attendanceRequestPeriod(request)),
                    if (request.kind == AttendanceRequestKind.leave) ...[
                      ('Working Days', '${request.leaveDays}'),
                      if (request.halfDayPart.isNotEmpty)
                        ('Half Day', request.halfDayPart),
                    ],
                    (
                      'Submitted',
                      '${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(request.createdAt, request.offsetMinutes)))} · ${AttendanceClock.time(request.createdAt, request.offsetMinutes)}'
                    ),
                  ]),
                  if (request.kind == AttendanceRequestKind.correction) ...[
                    const AttendanceHeading('Requested changes'),
                    AttendanceValues(rows: [
                      (
                        'Previous Check-in',
                        AttendanceClock.time(
                            original?.checkIn, request.offsetMinutes)
                      ),
                      (
                        'Previous Check-out',
                        AttendanceClock.time(
                            original?.checkOut, request.offsetMinutes)
                      ),
                      (
                        'Requested Check-in',
                        AttendanceClock.time(
                            request.proposedIn, request.offsetMinutes)
                      ),
                      (
                        'Requested Check-out',
                        '${AttendanceClock.time(request.proposedOut, request.offsetMinutes)}${request.proposedOut != null && AttendanceClock.key(AttendanceClock.wallTime(request.proposedOut!, request.offsetMinutes)) != request.day ? ' (next day)' : ''}'
                      ),
                    ]),
                  ],
                  if (request.kind == AttendanceRequestKind.offDaySwap) ...[
                    const AttendanceHeading('Swap details'),
                    AttendanceValues(rows: [
                      (
                        'Work on Weekly Off',
                        AttendanceClock.dayLabel(request.day)
                      ),
                      (
                        'Take Replacement Off',
                        AttendanceClock.dayLabel(request.endDay)
                      ),
                    ]),
                  ],
                  if (request.kind == AttendanceRequestKind.overtime) ...[
                    const AttendanceHeading('Overtime'),
                    AttendanceValues(rows: [
                      (
                        'Requested',
                        AttendanceClock.duration(request.overtimeMinutes)
                      ),
                      (
                        'Recorded Extra Work',
                        AttendanceClock.duration(AttendanceStore.instance
                            .dayFor(request.employeeId, request.day)
                            .overtimeMinutes)
                      ),
                    ]),
                  ],
                  const AttendanceHeading('Reason'),
                  AttendanceCard(
                      child: Text(request.reason,
                          style: TextStyle(
                              color: nec.textPrimary,
                              fontSize: 14,
                              height: 1.5))),
                  if (request.reviewedAt != null) ...[
                    const AttendanceHeading('Decision'),
                    AttendanceValues(rows: [
                      (
                        'Reviewed By',
                        EmployeeStore.instance
                                .byId(request.reviewerId ?? '')
                                ?.name ??
                            'Administrator'
                      ),
                      (
                        'Reviewed At',
                        '${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(request.reviewedAt!, request.offsetMinutes)))} · ${AttendanceClock.time(request.reviewedAt, request.offsetMinutes)}'
                      ),
                      (
                        'Note',
                        request.decisionNote.isEmpty
                            ? 'No additional note'
                            : request.decisionNote
                      ),
                    ]),
                  ],
                  if (canReview) ...[
                    const AttendanceHeading('Review request'),
                    AttendanceField(
                        label: 'Decision Note',
                        controller: _note,
                        hint: 'Required when rejecting a request',
                        maxLines: 3),
                    Row(children: [
                      Expanded(
                          child: NecButton(
                              label: 'Reject',
                              variant: NecButtonVariant.destructive,
                              loading: _busy,
                              onPressed: () => _act(approve: false))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: NecButton(
                              label: 'Approve',
                              loading: _busy,
                              onPressed: () => _act(approve: true)))
                    ]),
                  ],
                  if (canRevoke) ...[
                    const AttendanceHeading('Manage approval'),
                    AttendanceField(
                        label: 'Revocation Reason',
                        controller: _note,
                        hint: 'Explain why this approval should be removed',
                        maxLines: 3),
                    NecButton(
                        label: 'Revoke Overtime Approval',
                        fullWidth: true,
                        variant: NecButtonVariant.destructive,
                        loading: _busy,
                        onPressed: () => _act(revoke: true)),
                  ],
                  if (canCancel) ...[
                    const SizedBox(height: 20),
                    NecButton(
                        label: 'Cancel Request',
                        fullWidth: true,
                        variant: NecButtonVariant.tertiary,
                        loading: _busy,
                        onPressed: () async {
                          final confirmed = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                      title: const Text('Cancel this request?'),
                                      content: const Text(
                                          'The request will remain in history. Any reserved leave balance will be released.'),
                                      actions: [
                                        CupertinoDialogAction(
                                            onPressed: () => Navigator.pop(
                                                dialogContext, false),
                                            child: const Text('Keep')),
                                        CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            onPressed: () => Navigator.pop(
                                                dialogContext, true),
                                            child: const Text('Cancel Request'))
                                      ]));
                          if (mounted && confirmed == true) {
                            await _act();
                          }
                        })
                  ],
                  if (history.isNotEmpty) ...[
                    const AttendanceHeading('Request history'),
                    for (final event in history)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AttendanceCard(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(event.title,
                                    style: TextStyle(
                                        color: nec.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 5),
                                Text(
                                    '${EmployeeStore.instance.byId(event.actorId)?.name ?? 'Employee'} · ${AttendanceClock.dayLabel(AttendanceClock.key(AttendanceClock.wallTime(event.at, request.offsetMinutes)))} · ${AttendanceClock.time(event.at, request.offsetMinutes)}',
                                    style: TextStyle(
                                        color: nec.textTertiary,
                                        fontSize: 12,
                                        height: 1.4)),
                                if ((event.requestAfter?['decisionNote']
                                            as String? ??
                                        '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                      event.requestAfter!['decisionNote']
                                          as String,
                                      style: TextStyle(
                                          color: nec.textSecondary,
                                          fontSize: 12)),
                                ],
                              ]))),
                  ],
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 13))),
                ])));
      });
}
