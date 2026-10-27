import 'work_sms_options.dart';
import '../../../settings/data/auto_sms_settings_store.dart';
import 'package:intl/intl.dart';
import '../../data/work_queue_mapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import 'select_lead_sheet.dart';
import '../../../leads/data/lead_store.dart';
import '../../../tasks/data/work_item_store.dart';

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
  bool _saving = false;
  late String _selectedLead;
  String _selectedMethod = 'Call';
  DateTime _selectedDateTime = DateTime.now();
  TimeOfDay _selectedTimeOfDay = const TimeOfDay(hour: 16, minute: 0);
  final _purposeController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  bool _sendAutoSms = false;
  String _smsTarget = 'client_contact', _smsTiming = '15_minutes_before';
  int _reminderMinutes = 15;

  final methods = ['Call', 'WhatsApp', 'Email', 'Meeting', 'Other'];

  @override
  void initState() {
    super.initState();
    final sms = AutoSmsSettingsStore.instance;
    _sendAutoSms = sms.ready && sms.isAutoSmsEnabled;
    _smsTarget = sms.targetValue;
    _smsTiming = sms.timingValue;
    _selectedLead = widget.initialLeadName ?? '';
    final now = DateTime.now();
    _selectedDateTime = DateTime(now.year, now.month, now.day, 16, 0);
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _meetingLinkController.dispose();
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

  String get _formattedDateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
    );
    if (target == today) return 'Today';
    if (target == tomorrow) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(_selectedDateTime);
  }

  String get _formattedTimeText {
    final hour = _selectedTimeOfDay.hour == 0
        ? 12
        : (_selectedTimeOfDay.hour > 12
            ? _selectedTimeOfDay.hour - 12
            : _selectedTimeOfDay.hour);
    final minute = _selectedTimeOfDay.minute.toString().padLeft(2, '0');
    final period = _selectedTimeOfDay.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(now) ? now : _selectedDateTime,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTimeOfDay.hour,
          _selectedTimeOfDay.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay,
    );
    if (picked != null) {
      setState(() {
        _selectedTimeOfDay = picked;
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _buildAutoSmsPreview() {
    final lead = _selectedLead.isNotEmpty
        ? LeadStore.instance.leads
            .where((l) => l.company == _selectedLead)
            .firstOrNull
        : null;

    final rawContact = lead?.contactName?.trim();
    final customerName = (rawContact != null && rawContact.isNotEmpty)
        ? rawContact
        : (_selectedLead.isNotEmpty ? _selectedLead : null);

    final settings = AutoSmsSettingsStore.instance;
    if (!settings.ready || settings.smsTemplate.isEmpty) {
      return 'The server will generate the reminder using your organization’s SMS template.';
    }
    return settings.formatTemplate(
        clientName: customerName ?? '',
        date: DateFormat('d MMMM yyyy').format(_selectedDateTime),
        time: _formattedTimeText,
        purpose: _purposeController.text.trim(),
        repName:
            EmployeeStore.instance.byId(lead?.assignedEmployeeId ?? '')?.name ??
                '',
        meetingLink: _meetingLinkController.text.trim());
  }

  Future<void> _submitFollowUp() async {
    if (_saving) return;
    final lead = LeadStore.instance.leads
        .where((l) => l.company == _selectedLead)
        .firstOrNull;
    if (lead == null) {
      NecToast.show(context,
          message: 'Select a lead before scheduling.',
          type: NecToastType.error);
      return;
    }
    final purpose = _purposeController.text.trim();
    if (purpose.isEmpty) {
      NecToast.show(context,
          message: 'Enter the purpose.', type: NecToastType.error);
      return;
    }

    final scheduled = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      _selectedTimeOfDay.hour,
      _selectedTimeOfDay.minute,
    );

    final isAdmin = DemoSession.instance.isAdmin;
    final currentEmp = EmployeeStore.instance.currentEmployee;

    final int? assigneeEmpId = isAdmin
        ? (lead.assignedEmployeeId != null
            ? int.tryParse(
                lead.assignedEmployeeId!.replaceFirst('api_emp_', ''))
            : int.tryParse(currentEmp.backendId ?? ''))
        : int.tryParse(currentEmp.backendId ?? '');

    setState(() => _saving = true);
    try {
      final meetingLink = _meetingLinkController.text.trim();
      final saved = await WorkItemStore.instance.create({
        'type': 'followup',
        'title': purpose,
        'purpose': purpose,
        'method': _selectedMethod.toLowerCase(),
        'send_auto_sms': _sendAutoSms,
        'sms_target': _smsTarget,
        'sms_timing': _smsTiming,
        if (meetingLink.isNotEmpty) 'meeting_link': meetingLink,
        'reminder_minutes': _reminderMinutes,
        'details': {
          'purpose': purpose,
          'method': _selectedMethod.toLowerCase(),
          'send_auto_sms': _sendAutoSms,
          if (meetingLink.isNotEmpty) 'meeting_link': meetingLink,
          'reminder_minutes': _reminderMinutes,
        },
        'lead_id': int.tryParse(lead.id) ?? lead.id,
        if (assigneeEmpId != null) 'assignee_employee_id': assigneeEmpId,
        'priority': 'medium',
        'scheduled_at': scheduled.toIso8601String(),
      });

      final followUpId =
          int.tryParse(saved.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      NotificationService.instance
          .scheduleFollowUpReminder(
            id: followUpId,
            leadName: _selectedLead,
            purpose: purpose,
            scheduledAt: scheduled,
            reminderMinutes: _reminderMinutes,
            method: _selectedMethod,
            leadId: lead.id,
          )
          .ignore();

      if (!mounted) return;
      Navigator.pop(context, WorkQueueMapper.followUp(saved));
      NecToast.show(context,
          message:
              'Scheduled with ${_reminderMinutes == 0 ? "due" : "$_reminderMinutes min"} reminder',
          type: NecToastType.success);
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lead = _selectedLead.isNotEmpty
        ? LeadStore.instance.leads
            .where((l) => l.company == _selectedLead)
            .firstOrNull
        : null;

    final rawContact = lead?.contactName?.trim();

    return Container(
      height: MediaQuery.of(context).size.height * 0.74,
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Column(
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _openLeadPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? nec.bg
                                : nec.separator.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedLead.isEmpty
                                  ? nec.separator.withValues(alpha: 0.25)
                                  : AppColors.brandLight.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.brandLight
                                      .withValues(alpha: 0.15),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selectedLead.isEmpty
                                          ? 'Select a Lead'
                                          : _selectedLead,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedLead.isEmpty
                                            ? nec.textTertiary
                                            : nec.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedLead.isEmpty
                                          ? 'Tap to select client from leads'
                                          : (rawContact != null &&
                                                  rawContact.isNotEmpty
                                              ? 'Contact: $rawContact'
                                              : 'Linked Lead · Tap to change'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: nec.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSubtleLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedLead.isEmpty ? 'Select' : 'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: nec.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Method',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methods.map((m) {
                          final isSelected = _selectedMethod == m;
                          final unselectedBg = isDark
                              ? nec.bg
                              : nec.separator.withValues(alpha: 0.12);

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
                                color: isSelected
                                    ? AppColors.brandLight
                                    : unselectedBg,
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
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : nec.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
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
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? nec.bg
                                          : nec.separator
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: nec.separator
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formattedDateText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                        const Icon(
                                          CupertinoIcons.calendar,
                                          size: 16,
                                          color: AppColors.brandLight,
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
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? nec.bg
                                          : nec.separator
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: nec.separator
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formattedTimeText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                        const Icon(
                                          CupertinoIcons.clock,
                                          size: 16,
                                          color: AppColors.warning,
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.bell_fill,
                                size: 14,
                                color: Color(0xFF6355F6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reminder Notification',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _reminderMinutes == 0
                                ? 'At time of event'
                                : '$_reminderMinutes min before',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6355F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildReminderChip('1 min', 1, nec, isDark),
                            const SizedBox(width: 8),
                            _buildReminderChip('5 min', 5, nec, isDark),
                            const SizedBox(width: 8),
                            _buildReminderChip('15 min', 15, nec, isDark),
                            const SizedBox(width: 8),
                            _buildReminderChip('30 min', 30, nec, isDark),
                            const SizedBox(width: 8),
                            _buildReminderChip('1 hour', 60, nec, isDark),
                            const SizedBox(width: 8),
                            _buildReminderChip('At Time', 0, nec, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? nec.bg
                              : nec.separator.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _purposeController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 2,
                          maxLines: 4,
                          style: TextStyle(
                            fontSize: 14,
                            color: nec.textPrimary,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Discuss pricing, product demo...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: nec.textTertiary,
                              height: 1.35,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MEETING LINK (OPTIONAL)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: nec.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _meetingLinkController.text =
                                    'https://meet.google.com/new';
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.video_camera_solid,
                                  size: 13,
                                  color: nec.brand,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Google Meet',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: nec.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? nec.bg
                              : nec.separator.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _meetingLinkController,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 13,
                            color: nec.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            hintText:
                                'https://meet.google.com/... or Zoom link',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: nec.textTertiary,
                            ),
                            border: InputBorder.none,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 24,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 10, right: 6),
                              child: Icon(
                                CupertinoIcons.link,
                                size: 15,
                                color: Color(0xFF6355F6),
                              ),
                            ),
                            suffixIcon:
                                _meetingLinkController.text.trim().isNotEmpty
                                    ? CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _meetingLinkController.clear();
                                          setState(() {});
                                        },
                                        child: Icon(
                                          CupertinoIcons.clear_circled_solid,
                                          size: 16,
                                          color: nec.textTertiary,
                                        ),
                                      )
                                    : null,
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
                                const Icon(
                                  CupertinoIcons.chat_bubble_text_fill,
                                  size: 16,
                                  color: Color(0xFF6355F6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            ? 'Professional reminder queued for delivery'
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
                              WorkSmsOptions(
                                  target: _smsTarget,
                                  timing: _smsTiming,
                                  onTarget: (v) =>
                                      setState(() => _smsTarget = v),
                                  onTiming: (v) =>
                                      setState(() => _smsTiming = v)),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black38 : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF6355F6)
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.sparkles,
                                          size: 12,
                                          color: Color(0xFF6355F6),
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'OFFICIAL SMS MESSAGE PREVIEW',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6355F6),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _buildAutoSmsPreview(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: nec.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: NecButton(
                  label: _saving ? 'Scheduling...' : 'Schedule Follow-up',
                  loading: _saving,
                  onPressed: _saving ? null : _submitFollowUp,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderChip(
      String label, int minutes, NecColors nec, bool isDark) {
    final isSelected = _reminderMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _reminderMinutes = minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6355F6)
              : (isDark ? nec.bg : nec.separator.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6355F6)
                : nec.separator.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : nec.textPrimary,
          ),
        ),
      ),
    );
  }
}
