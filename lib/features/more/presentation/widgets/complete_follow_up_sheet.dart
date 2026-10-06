import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';

class CompleteFollowUpSheet extends StatefulWidget {
  final String leadName;

  const CompleteFollowUpSheet({
    super.key,
    required this.leadName,
  });

  @override
  State<CompleteFollowUpSheet> createState() => _CompleteFollowUpSheetState();
}

class _CompleteFollowUpSheetState extends State<CompleteFollowUpSheet> {
  String? _selectedOutcome;
  final _noteController = TextEditingController();

  final outcomes = [
    'Interested',
    'Call Later',
    'Need Meeting',
    'Visit Required',
    'No Response',
    'Not Interested',
    'Wrong Contact',
    'Custom',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

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
              // Drag handle
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
                'Complete Follow-up',
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
                        'What was the outcome of this follow-up?',
                        style: TextStyle(
                          fontSize: 14,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        'Note (optional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(color: nec.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Brief context or what was discussed...',
                          hintStyle: TextStyle(
                            color: nec.textTertiary,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: nec.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      NecButton(
                        label: 'Save Result',
                        onPressed: () {
                          Navigator.pop(context);
                          NecToast.show(
                            context,
                            message:
                                'Follow-up completed for ${widget.leadName}',
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
