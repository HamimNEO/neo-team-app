import '../domain/models/attendance_models.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

AttendancePolicy attendancePolicyFromApi(
    Map response, AttendancePolicy current) {
  final raw = response['settings'] is Map
      ? response['settings'] as Map
      : response['schedule'] is Map
          ? response['schedule'] as Map
          : response;
  int minute(Object? value, int fallback) {
    final parts = value?.toString().split(':');
    if (parts == null || parts.length < 2) return fallback;
    final hour = int.tryParse(parts[0]), min = int.tryParse(parts[1]);
    return hour == null || min == null ? fallback : hour * 60 + min;
  }

  final types = raw['leave_types'];
  return current.copyWith(
    startMinutes: minute(raw['office_opens_at'], current.startMinutes),
    endMinutes: minute(raw['office_closes_at'], current.endMinutes),
    requiredMinutes: (raw['required_work_minutes'] as num?)?.toInt(),
    graceMinutes: (raw['late_arrival_grace_minutes'] as num?)?.toInt(),
    paidBreakMinutes: (raw['paid_break_allowance_minutes'] as num?)?.toInt(),
    correctionWindowDays: (raw['attendance_fix_window_days'] as num?)?.toInt(),
    allowOffDayWork: raw['allow_work_on_off_days'] as bool?,
    allowBackdatedLeave: raw['allow_backdated_leave'] as bool?,
    overtimeApprovalRequired: raw['require_overtime_approval'] as bool?,
    trackingStart: raw['attendance_tracking_begins_on']?.toString(),
    offWeekdays: raw['weekly_off_days'] is List
        ? [
            for (final day in raw['weekly_off_days'] as List)
              if (_weekdays.contains(day)) _weekdays.indexOf(day) + 1
          ]
        : null,
    leaveTypes: types is Map
        ? [
            for (final entry in types.entries)
              if (entry.value is Map)
                LeaveType(
                    id: entry.key.toString(),
                    name: entry.value['label']?.toString() ??
                        entry.key.toString(),
                    annualDays: (entry.value['days'] as num?)?.toInt(),
                    paid: entry.value['paid'] != false,
                    enabled: entry.value['enabled'] != false)
          ]
        : null,
    holidays: response['holidays'] is List
        ? [
            for (final item in response['holidays'] as List)
              if (item is Map && (item['holiday_date'] ?? item['date']) != null)
                AttendanceHoliday(
                    id: item['id']?.toString(),
                    day: (item['holiday_date'] ?? item['date']).toString(),
                    name: item['name']?.toString() ?? '')
          ]
        : null,
  );
}

Map<String, dynamic> attendancePolicyToApi(AttendancePolicy policy) {
  String time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  return {
    'office_opens_at': time(policy.startMinutes),
    'office_closes_at': time(policy.endMinutes),
    'required_work_minutes': policy.requiredMinutes,
    'late_arrival_grace_minutes': policy.graceMinutes,
    'paid_break_allowance_minutes': policy.paidBreakMinutes,
    'attendance_fix_window_days': policy.correctionWindowDays,
    'allow_work_on_off_days': policy.allowOffDayWork,
    'allow_backdated_leave': policy.allowBackdatedLeave,
    'require_overtime_approval': policy.overtimeApprovalRequired,
    'attendance_tracking_begins_on': policy.trackingStart,
    'weekly_off_days': [
      for (final day in policy.offWeekdays) _weekdays[day - 1]
    ],
    'leave_types': {
      for (final type in policy.leaveTypes)
        type.id: {
          'label': type.name,
          'days': type.annualDays,
          'paid': type.paid,
          'enabled': type.enabled
        }
    },
    'leave_policies': {
      for (final type in policy.leaveTypes) type.id: type.annualDays
    }
  };
}
