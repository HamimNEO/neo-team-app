import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../team/domain/models/employee.dart';
import 'attendance_clock.dart';
import 'attendance_store.dart';

class AttendanceExport {
  static String csv(DateTime month, List<Employee> employees) {
    final rows = <List<String>>[
      [
        'Employee ID',
        'Employee',
        'Department',
        'Date',
        'Status',
        'Check-in',
        'Check-out',
        'Worked minutes',
        'Late minutes',
        'Leave days',
        'Extra minutes',
        'Approved overtime minutes',
        'UTC offset minutes',
        'Note'
      ],
    ];
    for (final employee in employees) {
      for (final day in AttendanceStore.instance.monthFor(employee.id, month)) {
        rows.add([
          employee.displayCode,
          employee.name,
          employee.department.split(' · ').first,
          day.day,
          day.status.label,
          AttendanceClock.time(day.record?.checkIn, day.record?.offsetMinutes),
          AttendanceClock.time(day.record?.checkOut, day.record?.offsetMinutes),
          '${day.workedMinutes}',
          '${day.lateMinutes}',
          '${day.leaveDays}',
          '${day.overtimeMinutes}',
          '${day.approvedOvertimeMinutes}',
          '${day.record?.offsetMinutes ?? AttendanceClock.offsetMinutes}',
          day.note
        ]);
      }
    }
    String cell(String text) {
      final safe = RegExp(r'^\s*[=+@\-\t\r]').hasMatch(text) ? "'$text" : text;
      return '"${safe.replaceAll('"', '""')}"';
    }

    return rows.map((row) => row.map(cell).join(',')).join('\r\n');
  }

  static Future<bool> save(DateTime month, List<Employee> employees) async {
    final name =
        'NEC-attendance-${AttendanceClock.key(month).substring(0, 7)}.csv';
    final bytes =
        Uint8List.fromList(utf8.encode('\uFEFF${csv(month, employees)}'));
    if (kIsWeb) {
      await XFile.fromData(bytes, name: name, mimeType: 'text/csv')
          .saveTo(name);
      return true;
    }
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Attendance',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: mobile ? bytes : null);
    if (path == null) {
      return false;
    }
    if (!mobile) {
      await XFile.fromData(bytes, name: name, mimeType: 'text/csv')
          .saveTo(path);
    }
    return true;
  }
}
