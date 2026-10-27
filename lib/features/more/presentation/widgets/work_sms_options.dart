import 'package:flutter/material.dart';

/// Wire values match the follow-up/visit contracts; scheduling remains server-side.
class WorkSmsOptions extends StatelessWidget {
  const WorkSmsOptions(
      {super.key,
      required this.target,
      required this.timing,
      required this.onTarget,
      required this.onTiming});

  final String target, timing;
  final ValueChanged<String> onTarget, onTiming;
  static const targets = {
    'client_contact': 'Client',
    'assigned_representative': 'Assigned employee',
    'both': 'Client and employee'
  };
  static const timings = {
    'immediately': 'Immediately',
    'scheduled_time': 'At scheduled time',
    '15_minutes_before': '15 minutes before',
    '30_minutes_before': '30 minutes before',
    '1_hour_before': '1 hour before'
  };

  @override
  Widget build(BuildContext context) => Column(children: [
        DropdownButtonFormField<String>(
            initialValue: target,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'SMS recipient'),
            items: [
              for (final e in targets.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value))
            ],
            onChanged: (v) {
              if (v != null) onTarget(v);
            }),
        DropdownButtonFormField<String>(
            initialValue: timing,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'SMS timing'),
            items: [
              for (final e in timings.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value))
            ],
            onChanged: (v) {
              if (v != null) onTiming(v);
            }),
      ]);
}
