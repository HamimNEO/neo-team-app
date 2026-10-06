import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';

class VisitReportSheet extends StatefulWidget {
  final String leadName;
  final VoidCallback onSaved;

  const VisitReportSheet({
    super.key,
    required this.leadName,
    required this.onSaved,
  });

  @override
  State<VisitReportSheet> createState() => _VisitReportSheetState();
}

class _VisitReportSheetState extends State<VisitReportSheet> {
  final _meetingWithController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedOutcome;
  String _selectedNextAction = 'Schedule Follow-up';

  final outcomes = [
    'Very Interested',
    'Interested',
    'Needs More Info',
    'Not Ready',
    'Not Interested',
  ];

  final nextActions = [
    'Schedule Follow-up',
    'Another Visit',
    'Negotiation',
    'No Action',
    'Mark Lost',
  ];

  @override
  void dispose() {
    _meetingWithController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Visit Report',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting With',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: nec.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _meetingWithController,
                          style:
                              TextStyle(color: nec.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Name / Position',
                            hintStyle: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Outcome',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: nec.bg,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: List.generate(outcomes.length, (index) {
                            final outcome = outcomes[index];
                            final isSelected = _selectedOutcome == outcome;
                            final isLast = index == outcomes.length - 1;

                            return Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedOutcome = outcome;
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    color: isSelected
                                        ? nec.brand.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    child: Text(
                                      outcome,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? nec.brand
                                            : nec.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: nec.separator.withValues(alpha: 0.2),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: nec.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 4,
                          style:
                              TextStyle(color: nec.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'Key discussion points, client requirements...',
                            hintStyle: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Next Action',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: nextActions.map((action) {
                          final isSelected = _selectedNextAction == action;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedNextAction = action;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? nec.brand : nec.bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                action,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : nec.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      NecButton(
                        label: 'Save Report',
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSaved();
                          NecToast.show(
                            context,
                            message: 'Visit completed & report saved!',
                            type: NecToastType.success,
                          );
                        },
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
