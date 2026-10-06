enum AttendanceStatus {
  present('Present'),
  late('Late'),
  working('Working'),
  onBreak('On break'),
  halfDay('Half day'),
  shortDay('Short day'),
  absent('Absent'),
  leave('On leave'),
  offDay('Day off'),
  holiday('Holiday'),
  swappedOff('Swapped off'),
  upcoming('Upcoming'),
  notCheckedIn('Not checked in'),
  notTracked('Not tracked');

  final String label;

  const AttendanceStatus(this.label);
}

enum AttendanceRequestKind {
  leave('Leave'),
  correction('Attendance fix'),
  offDaySwap('Off-day swap'),
  overtime('Overtime');

  final String label;

  const AttendanceRequestKind(this.label);
}

enum AttendanceRequestStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  final String label;

  const AttendanceRequestStatus(this.label);
}

class LeaveType {
  final String id;
  final String name;
  final int? annualDays;
  final bool paid;
  final bool enabled;

  const LeaveType(
      {required this.id,
      required this.name,
      this.annualDays,
      this.paid = true,
      this.enabled = true});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'annualDays': annualDays,
        'paid': paid,
        'enabled': enabled
      };

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
      id: json['id'] as String,
      name: json['name'] as String,
      annualDays: json['annualDays'] as int?,
      paid: json['paid'] as bool,
      enabled: json['enabled'] as bool);
}

class AttendanceHoliday {
  final String day;
  final String name;

  const AttendanceHoliday({required this.day, required this.name});

  Map<String, dynamic> toJson() => {'day': day, 'name': name};

  factory AttendanceHoliday.fromJson(Map<String, dynamic> json) =>
      AttendanceHoliday(
          day: json['day'] as String, name: json['name'] as String);
}

class AttendancePolicy {
  final int startMinutes;
  final int endMinutes;
  final int requiredMinutes;
  final int graceMinutes;
  final int paidBreakMinutes;
  final int correctionWindowDays;
  final List<int> offWeekdays;
  final List<AttendanceHoliday> holidays;
  final List<LeaveType> leaveTypes;
  final bool allowOffDayWork;
  final bool allowBackdatedLeave;
  final bool overtimeApprovalRequired;
  final String trackingStart;

  const AttendancePolicy(
      {this.startMinutes = 600,
      this.endMinutes = 1080,
      this.requiredMinutes = 480,
      this.graceMinutes = 15,
      this.paidBreakMinutes = 0,
      this.correctionWindowDays = 31,
      this.offWeekdays = const [5],
      this.holidays = const [],
      this.allowOffDayWork = true,
      this.allowBackdatedLeave = false,
      this.overtimeApprovalRequired = true,
      required this.trackingStart,
      this.leaveTypes = const [
        LeaveType(id: 'annual', name: 'Annual Leave', annualDays: 14),
        LeaveType(id: 'sick', name: 'Sick Leave', annualDays: 10),
        LeaveType(id: 'casual', name: 'Casual Leave', annualDays: 10),
        LeaveType(id: 'unpaid', name: 'Unpaid Leave', paid: false),
      ]});

  int get shiftMinutes => (endMinutes - startMinutes + 1440) % 1440;

  bool get overnight => endMinutes < startMinutes;

  AttendancePolicy copyWith(
          {int? startMinutes,
          int? endMinutes,
          int? requiredMinutes,
          int? graceMinutes,
          int? paidBreakMinutes,
          int? correctionWindowDays,
          List<int>? offWeekdays,
          List<AttendanceHoliday>? holidays,
          List<LeaveType>? leaveTypes,
          bool? allowOffDayWork,
          bool? allowBackdatedLeave,
          bool? overtimeApprovalRequired,
          String? trackingStart}) =>
      AttendancePolicy(
          startMinutes: startMinutes ?? this.startMinutes,
          endMinutes: endMinutes ?? this.endMinutes,
          requiredMinutes: requiredMinutes ?? this.requiredMinutes,
          graceMinutes: graceMinutes ?? this.graceMinutes,
          paidBreakMinutes: paidBreakMinutes ?? this.paidBreakMinutes,
          correctionWindowDays:
              correctionWindowDays ?? this.correctionWindowDays,
          offWeekdays: List.unmodifiable(offWeekdays ?? this.offWeekdays),
          holidays: List.unmodifiable(holidays ?? this.holidays),
          leaveTypes: List.unmodifiable(leaveTypes ?? this.leaveTypes),
          allowOffDayWork: allowOffDayWork ?? this.allowOffDayWork,
          allowBackdatedLeave: allowBackdatedLeave ?? this.allowBackdatedLeave,
          overtimeApprovalRequired:
              overtimeApprovalRequired ?? this.overtimeApprovalRequired,
          trackingStart: trackingStart ?? this.trackingStart);

  Map<String, dynamic> toJson() => {
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'requiredMinutes': requiredMinutes,
        'graceMinutes': graceMinutes,
        'paidBreakMinutes': paidBreakMinutes,
        'correctionWindowDays': correctionWindowDays,
        'offWeekdays': offWeekdays,
        'holidays': holidays.map((item) => item.toJson()).toList(),
        'leaveTypes': leaveTypes.map((item) => item.toJson()).toList(),
        'allowOffDayWork': allowOffDayWork,
        'allowBackdatedLeave': allowBackdatedLeave,
        'overtimeApprovalRequired': overtimeApprovalRequired,
        'trackingStart': trackingStart
      };

  factory AttendancePolicy.fromJson(Map<String, dynamic> json) =>
      AttendancePolicy(
          startMinutes: json['startMinutes'] as int,
          endMinutes: json['endMinutes'] as int,
          requiredMinutes: json['requiredMinutes'] as int,
          graceMinutes: json['graceMinutes'] as int,
          paidBreakMinutes: json['paidBreakMinutes'] as int,
          correctionWindowDays: json['correctionWindowDays'] as int,
          offWeekdays: List<int>.from(json['offWeekdays'] as List),
          holidays: (json['holidays'] as List)
              .map((item) => AttendanceHoliday.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
          leaveTypes: (json['leaveTypes'] as List)
              .map((item) =>
                  LeaveType.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
          allowOffDayWork: json['allowOffDayWork'] as bool,
          allowBackdatedLeave: json['allowBackdatedLeave'] as bool,
          overtimeApprovalRequired: json['overtimeApprovalRequired'] as bool,
          trackingStart: json['trackingStart'] as String);
}

class AttendanceBreak {
  final DateTime start;
  final DateTime? end;

  const AttendanceBreak(this.start, [this.end]);

  Map<String, dynamic> toJson() =>
      {'start': start.toIso8601String(), 'end': end?.toIso8601String()};

  factory AttendanceBreak.fromJson(Map<String, dynamic> json) =>
      AttendanceBreak(DateTime.parse(json['start'] as String),
          json['end'] == null ? null : DateTime.parse(json['end'] as String));
}

class AttendanceRecord {
  final String employeeId;
  final String day;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final List<AttendanceBreak> breaks;
  final int offsetMinutes;
  final int requiredMinutes;
  final int graceMinutes;
  final int paidBreakMinutes;
  final DateTime expectedStart;
  final int shiftMinutes;
  final bool wasWorkingDay;
  final int revision;
  final bool corrected;
  final String note;

  const AttendanceRecord(
      {required this.employeeId,
      required this.day,
      this.checkIn,
      this.checkOut,
      this.breaks = const [],
      required this.offsetMinutes,
      required this.requiredMinutes,
      required this.expectedStart,
      required this.shiftMinutes,
      required this.graceMinutes,
      required this.paidBreakMinutes,
      this.revision = 1,
      this.corrected = false,
      this.note = '',
      this.wasWorkingDay = true});

  bool get open => checkIn != null && checkOut == null;

  bool get onBreak => breaks.isNotEmpty && breaks.last.end == null;

  int breakSeconds(DateTime now) {
    if (checkIn == null) {
      return 0;
    }
    final stop = checkOut ?? now;
    var seconds = 0;
    for (final item in breaks) {
      final start = item.start.isBefore(checkIn!) ? checkIn! : item.start;
      final end = (item.end ?? stop).isAfter(stop) ? stop : (item.end ?? stop);
      if (end.isAfter(start)) {
        seconds += end.difference(start).inSeconds;
      }
    }
    return seconds;
  }

  int workedSeconds(DateTime now) {
    if (checkIn == null) {
      return 0;
    }
    final gross = (checkOut ?? now).difference(checkIn!).inSeconds;
    final unpaid =
        (breakSeconds(now) - paidBreakMinutes * 60).clamp(0, 100000000);
    return (gross - unpaid).clamp(0, 100000000).toInt();
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'day': day,
        'checkIn': checkIn?.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
        'breaks': breaks.map((item) => item.toJson()).toList(),
        'offsetMinutes': offsetMinutes,
        'requiredMinutes': requiredMinutes,
        'expectedStart': expectedStart.toIso8601String(),
        'shiftMinutes': shiftMinutes,
        'wasWorkingDay': wasWorkingDay,
        'graceMinutes': graceMinutes,
        'paidBreakMinutes': paidBreakMinutes,
        'revision': revision,
        'corrected': corrected,
        'note': note
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
          employeeId: json['employeeId'] as String,
          day: json['day'] as String,
          checkIn: json['checkIn'] == null
              ? null
              : DateTime.parse(json['checkIn'] as String),
          checkOut: json['checkOut'] == null
              ? null
              : DateTime.parse(json['checkOut'] as String),
          breaks: (json['breaks'] as List)
              .map((item) => AttendanceBreak.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
          offsetMinutes: json['offsetMinutes'] as int,
          requiredMinutes: json['requiredMinutes'] as int,
          expectedStart: DateTime.parse(json['expectedStart'] as String),
          shiftMinutes: json['shiftMinutes'] as int,
          wasWorkingDay: json['wasWorkingDay'] as bool? ?? true,
          graceMinutes: json['graceMinutes'] as int,
          paidBreakMinutes: json['paidBreakMinutes'] as int,
          revision: json['revision'] as int,
          corrected: json['corrected'] as bool,
          note: json['note'] as String);
}

/// Dates are civil organization dates; event timestamps are always UTC.
class AttendanceRequest {
  final String id;
  final String employeeId;
  final AttendanceRequestKind kind;
  final AttendanceRequestStatus status;
  final String day;
  final String endDay;
  final String reason;
  final DateTime createdAt;
  final int offsetMinutes;
  final String typeId;
  final String typeName;
  final Map<String, int> leaveUnits;
  final String halfDayPart;
  final DateTime? proposedIn;
  final DateTime? proposedOut;
  final int? originalRevision;
  final Map<String, dynamic>? originalRecord;
  final int overtimeMinutes;
  final String? reviewerId;
  final DateTime? reviewedAt;
  final String decisionNote;

  const AttendanceRequest(
      {required this.id,
      required this.employeeId,
      required this.kind,
      this.status = AttendanceRequestStatus.pending,
      required this.day,
      required this.endDay,
      required this.reason,
      required this.createdAt,
      required this.offsetMinutes,
      this.typeId = '',
      this.typeName = '',
      this.leaveUnits = const {},
      this.halfDayPart = '',
      this.proposedIn,
      this.proposedOut,
      this.originalRevision,
      this.originalRecord,
      this.overtimeMinutes = 0,
      this.reviewerId,
      this.reviewedAt,
      this.decisionNote = ''});

  double get leaveDays =>
      leaveUnits.values.fold(0, (sum, value) => sum + value) / 2;

  bool get reserves =>
      status == AttendanceRequestStatus.pending ||
      status == AttendanceRequestStatus.approved;

  AttendanceRequest decide(AttendanceRequestStatus status, String actorId,
          String note, DateTime now) =>
      AttendanceRequest.fromJson({
        ...toJson(),
        'status': status.name,
        'reviewerId': actorId,
        'reviewedAt': now.toIso8601String(),
        'decisionNote': note
      });

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'kind': kind.name,
        'status': status.name,
        'day': day,
        'endDay': endDay,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
        'offsetMinutes': offsetMinutes,
        'typeId': typeId,
        'typeName': typeName,
        'leaveUnits': leaveUnits,
        'halfDayPart': halfDayPart,
        'proposedIn': proposedIn?.toIso8601String(),
        'proposedOut': proposedOut?.toIso8601String(),
        'originalRevision': originalRevision,
        'originalRecord': originalRecord,
        'overtimeMinutes': overtimeMinutes,
        'reviewerId': reviewerId,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'decisionNote': decisionNote
      };

  factory AttendanceRequest.fromJson(Map<String, dynamic> json) =>
      AttendanceRequest(
          id: json['id'] as String,
          employeeId: json['employeeId'] as String,
          kind: AttendanceRequestKind.values.byName(json['kind'] as String),
          status:
              AttendanceRequestStatus.values.byName(json['status'] as String),
          day: json['day'] as String,
          endDay: json['endDay'] as String,
          reason: json['reason'] as String,
          createdAt: DateTime.parse(json['createdAt'] as String),
          offsetMinutes: json['offsetMinutes'] as int,
          typeId: json['typeId'] as String,
          typeName: json['typeName'] as String,
          leaveUnits: Map<String, int>.from(json['leaveUnits'] as Map),
          halfDayPart: json['halfDayPart'] as String,
          proposedIn: json['proposedIn'] == null
              ? null
              : DateTime.parse(json['proposedIn'] as String),
          proposedOut: json['proposedOut'] == null
              ? null
              : DateTime.parse(json['proposedOut'] as String),
          originalRevision: json['originalRevision'] as int?,
          originalRecord: json['originalRecord'] as Map<String, dynamic>?,
          overtimeMinutes: json['overtimeMinutes'] as int,
          reviewerId: json['reviewerId'] as String?,
          reviewedAt: json['reviewedAt'] == null
              ? null
              : DateTime.parse(json['reviewedAt'] as String),
          decisionNote: json['decisionNote'] as String);
}

class AttendanceEvent {
  final String employeeId;
  final String actorId;
  final String day;
  final String title;
  final DateTime at;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final Map<String, dynamic>? requestBefore;
  final Map<String, dynamic>? requestAfter;

  const AttendanceEvent(
      {required this.employeeId,
      required this.actorId,
      required this.day,
      required this.title,
      required this.at,
      this.before,
      this.after,
      this.requestBefore,
      this.requestAfter});

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'actorId': actorId,
        'day': day,
        'title': title,
        'at': at.toIso8601String(),
        'before': before,
        'after': after,
        'requestBefore': requestBefore,
        'requestAfter': requestAfter
      };

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) =>
      AttendanceEvent(
          employeeId: json['employeeId'] as String,
          actorId: json['actorId'] as String,
          day: json['day'] as String,
          title: json['title'] as String,
          at: DateTime.parse(json['at'] as String),
          before: json['before'] as Map<String, dynamic>?,
          after: json['after'] as Map<String, dynamic>?,
          requestBefore: json['requestBefore'] as Map<String, dynamic>?,
          requestAfter: json['requestAfter'] as Map<String, dynamic>?);
}

class AttendanceState {
  final AttendancePolicy policy;
  final List<AttendanceRecord> records;
  final List<AttendanceRequest> requests;
  final List<AttendanceEvent> events;

  const AttendanceState(
      {required this.policy,
      this.records = const [],
      this.requests = const [],
      this.events = const []});

  AttendanceState copyWith(
          {AttendancePolicy? policy,
          List<AttendanceRecord>? records,
          List<AttendanceRequest>? requests,
          List<AttendanceEvent>? events}) =>
      AttendanceState(
          policy: policy ?? this.policy,
          records: List.unmodifiable(records ?? this.records),
          requests: List.unmodifiable(requests ?? this.requests),
          events: List.unmodifiable(events ?? this.events));

  Map<String, dynamic> toJson() => {
        'version': 1,
        'policy': policy.toJson(),
        'records': records.map((item) => item.toJson()).toList(),
        'requests': requests.map((item) => item.toJson()).toList(),
        'events': events.map((item) => item.toJson()).toList()
      };

  factory AttendanceState.fromJson(Map<String, dynamic> json) =>
      AttendanceState(
          policy: AttendancePolicy.fromJson(
              Map<String, dynamic>.from(json['policy'] as Map)),
          records: (json['records'] as List)
              .map((item) => AttendanceRecord.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
          requests: (json['requests'] as List)
              .map((item) => AttendanceRequest.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
          events: (json['events'] as List)
              .map((item) => AttendanceEvent.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList());
}

class AttendanceDay {
  final String day;
  final AttendanceStatus status;
  final AttendanceRecord? record;
  final int workedMinutes;
  final int requiredMinutes;
  final int overtimeMinutes;
  final int approvedOvertimeMinutes;
  final int lateMinutes;
  final double leaveDays;
  final String note;

  const AttendanceDay(
      {required this.day,
      required this.status,
      this.record,
      this.workedMinutes = 0,
      this.requiredMinutes = 0,
      this.overtimeMinutes = 0,
      this.approvedOvertimeMinutes = 0,
      this.lateMinutes = 0,
      this.leaveDays = 0,
      this.note = ''});
}

class LeaveBalance {
  final LeaveType type;
  final double used;
  final double pending;

  const LeaveBalance(this.type, this.used, this.pending);

  double? get remaining =>
      type.annualDays == null ? null : type.annualDays! - used - pending;
}
