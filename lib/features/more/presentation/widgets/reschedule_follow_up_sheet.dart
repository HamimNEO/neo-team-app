import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';

class RescheduleFollowUpSheet extends StatefulWidget {
  final String currentSchedule;
  final String leadName;

  const RescheduleFollowUpSheet({
    super.key,
    required this.currentSchedule,
    required this.leadName,
  });

  @override
  State<RescheduleFollowUpSheet> createState() =>
      _RescheduleFollowUpSheetState();
}

class _RescheduleFollowUpSheetState extends State<RescheduleFollowUpSheet> {
  String _selectedDate = 'Tomorrow';
  String _selectedTime = '11:30 AM';

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Reschedule Follow-up',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: nec.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currentSchedule,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 30)),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate =
                                    '${date.day}/${date.month}/${date.year}';
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: nec.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.calendar,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: nec.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  const TimeOfDay(hour: 11, minute: 30),
                            );
                            if (time != null) {
                              setState(() {
                                _selectedTime = time.format(context);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: nec.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: nec.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NecButton(
                label: 'Reschedule',
                onPressed: () {
                  Navigator.pop(context);
                  NecToast.show(
                    context,
                    message:
                        'Rescheduled follow-up to $_selectedDate at $_selectedTime',
                    type: NecToastType.success,
                  );
                },
                fullWidth: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
