import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/attendance_clock.dart';

Future<int?> pickAttendanceTime(BuildContext context, int initial) {
  var minutes = initial;
  final nec = Theme.of(context).extension<NecColors>()!;
  return showCupertinoModalPopup<int>(
      context: context,
      builder: (sheetContext) => CupertinoTheme(
          data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              primaryColor: nec.brand),
          child: Material(
              color: nec.surface,
              child: SafeArea(
                  top: false,
                  child: SizedBox(
                      height: 300,
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  child: const Text('Cancel')),
                              CupertinoButton(
                                  onPressed: () =>
                                      Navigator.pop(sheetContext, minutes),
                                  child: const Text('Done')),
                            ]),
                        Expanded(
                            child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: DateTime(
                                    2000, 1, 1, initial ~/ 60, initial % 60),
                                onDateTimeChanged: (date) =>
                                    minutes = date.hour * 60 + date.minute)),
                      ]))))));
}

Future<String?> chooseAttendanceOption(
        BuildContext context, String title, List<(String, String)> options) =>
    showCupertinoModalPopup<String>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
            title: Text(title),
            actions: options
                .map((item) => CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(sheetContext, item.$1),
                    child: Text(item.$2)))
                .toList(),
            cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'))));

Future<DateTime?> pickAttendanceDate(BuildContext context, DateTime initial,
    {DateTime? first, DateTime? last}) {
  final minimum = DateUtils.dateOnly(first ?? DateTime(2000));
  final maximum = DateUtils.dateOnly(
      last ?? DateTime(AttendanceClock.today.year + 3, 12, 31));
  final date = DateTime(initial.year, initial.month, initial.day);
  return showDatePicker(
      context: context,
      initialDate: date.isBefore(minimum)
          ? minimum
          : date.isAfter(maximum)
              ? maximum
              : date,
      firstDate: minimum,
      lastDate: maximum);
}
