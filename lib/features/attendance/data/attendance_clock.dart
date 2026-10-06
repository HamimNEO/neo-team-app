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

  static DateTime wallTime(DateTime utc, [int? offset]) =>
      utc.toUtc().add(Duration(minutes: offset ?? offsetMinutes));

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
}
