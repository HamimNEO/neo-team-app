import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/follow_up.dart';
import 'select_lead_sheet.dart';

class AddFollowUpSheet extends StatefulWidget {
  final String? initialLeadName;

  const AddFollowUpSheet({
    super.key,
    this.initialLeadName,
  });

  @override
  State<AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<AddFollowUpSheet> {
  late String _selectedLead;
  String _selectedMethod = 'Call';
  String _selectedDate = 'Today';
  String _selectedTime = '4:00 PM';
  final _purposeController = TextEditingController();
  bool _sendAutoSms = true;

  final methods = ['Call', 'WhatsApp', 'Email', 'Meeting', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedLead = widget.initialLeadName ?? 'Blue Wave Resort';
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  void _openLeadPicker() async {
    final lead = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SelectLeadSheet(currentLeadName: _selectedLead),
    );
    if (lead != null && lead.isNotEmpty) {
      setState(() {
        _selectedLead = lead;
      });
    }
  }

  void _submitFollowUp() {
    final purpose = _purposeController.text.trim().isEmpty
        ? 'General follow-up'
        : _purposeController.text.trim();

    final newFollowUp = FollowUp(
      id: 'fu_${DateTime.now().millisecondsSinceEpoch % 1000}',
      leadName: _selectedLead,
      purpose: purpose,
      method: _selectedMethod,
      dateText: _selectedDate,
      timeText: _selectedTime,
      assigneeName: 'Shahina Akter',
      assigneeInitials: 'SA',
      statusGroup: _selectedDate == 'Today' ? 'Today' : 'Tomorrow',
      isAutoSmsEnabled: _sendAutoSms,
      autoSmsStatus: _sendAutoSms ? 'Scheduled' : 'Disabled',
      autoSmsRecipientPhone: '+880 1711-222222',
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newFollowUp);
    }

    NecToast.show(
      context,
      message: _sendAutoSms
          ? 'Follow-up scheduled & Auto-SMS queued'
          : 'Follow-up scheduled successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
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
                  'Add Follow-up',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _openLeadPicker,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.brandLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brandLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.building_2_fill,
                          color: AppColors.brandLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLead,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lead · tap to change',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Method',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: methods.map((m) {
                  final isSelected = _selectedMethod == m;
                  final unselectedBg =
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMethod = m;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandLight : unselectedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandLight
                              : nec.separator.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : nec.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = _selectedDate == 'Today'
                                  ? 'Tomorrow'
                                  : 'Today';
                            });
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? nec.bg
                                  : nec.separator.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: nec.textPrimary,
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.calendar,
                                  size: 16,
                                  color: nec.textTertiary,
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
                          'Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTime = _selectedTime == '4:00 PM'
                                  ? '11:30 AM'
                                  : '4:00 PM';
                            });
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? nec.bg
                                  : nec.separator.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: nec.textPrimary,
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 16,
                                  color: nec.textTertiary,
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
              const SizedBox(height: 20),
              Text(
                'Purpose',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _purposeController,
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Discuss pricing, product demo...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C22)
                      : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF6355F6)
                        .withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.chat_bubble_text_fill,
                            size: 16, color: Color(0xFF6355F6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send Auto-SMS to Client',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              Text(
                                _sendAutoSms
                                    ? 'Alert queued (15m before meeting)'
                                    : 'SMS notification disabled',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _sendAutoSms
                                      ? const Color(0xFF6355F6)
                                      : nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch.adaptive(
                            value: _sendAutoSms,
                            onChanged: (val) =>
                                setState(() => _sendAutoSms = val),
                            activeTrackColor: const Color(0xFF6355F6),
                            activeThumbColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_sendAutoSms) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: nec.separator.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          'SMS Preview: "Hello $_selectedLead, reminder from NEONECY regarding your follow-up on $_selectedDate at $_selectedTime."',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                            color: nec.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NecButton(
                label: 'Schedule Follow-up',
                onPressed: _submitFollowUp,
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
