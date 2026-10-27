import 'package:intl/intl.dart';
import '../../settings/data/system_settings_store.dart';
import '../../settings/domain/models/system_settings.dart';

class AttendanceClock {
  static int get offsetMinutes =>
      switch (SystemSettingsStore.instance.value.timezone) {
        OrganizationTimezone.dhaka => 360,
        OrganizationTimezone.kolkata => 330,
        OrganizationTimezone.kathmandu => 345,
        OrganizationTimezone.dubai => 240,
        OrganizationTimezone.singapore => 480,
        OrganizationTimezone.tokyo => 540,
        OrganizationTimezone.utc => 0,
      };

  static String get timezone =>
      SystemSettingsStore.instance.value.timezone.label;

  static DateTime get now => DateTime.now().toUtc();

  static DateTime wallTime(DateTime utc, [int? offset]) {
    final effectiveOffset = offset ?? offsetMinutes;
    var target = utc.toUtc();
    if (target
        .isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      final adjusted = target.subtract(Duration(minutes: effectiveOffset));
      if (!adjusted
          .isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
        target = adjusted;
      }
    }
    return target.add(Duration(minutes: effectiveOffset));
  }

  static DateTime get today => date(key(wallTime(now)));

  static String key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime date(String key) => DateTime.parse('${key}T00:00:00Z');

  static DateTime instant(String day, int minute, [int? offset]) =>
      date(day).add(Duration(minutes: minute - (offset ?? offsetMinutes)));

  static String time(DateTime? value, [int? offset]) => value == null
      ? '—'
      : DateFormat('h:mm a').format(wallTime(value, offset));

  static String minutesTime(int minutes) => DateFormat('h:mm a')
      .format(DateTime.utc(2000, 1, 1).add(Duration(minutes: minutes)));

  static String duration(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';

  static String dayLabel(String day) =>
      DateFormat('EEE, d MMM yyyy').format(date(day));

  static List<DateTime> monthDays(DateTime month) => List.generate(
      DateTime.utc(month.year, month.month + 1, 0).day,
      (index) => DateTime.utc(month.year, month.month, index + 1));

  static DateTime? parseServerTimestamp(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null') return null;

    final explicitNonzeroTz =
        RegExp(r'([+-](?!00(?::?00)?$)\d{2}(?::?\d{2})?)$').hasMatch(str);
    if (explicitNonzeroTz) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed.toUtc();
    }

    final match =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2}):(\d{2})')
            .firstMatch(str);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);

      final offset = offsetMinutes;
      final wallUtc = DateTime.utc(year, month, day, hour, minute, second);
      return wallUtc.subtract(Duration(minutes: offset));
    }
    return DateTime.tryParse(str);
  }
}
