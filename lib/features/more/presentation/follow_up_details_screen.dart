import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../settings/data/auto_sms_settings_store.dart';
import 'widgets/complete_follow_up_sheet.dart';
import 'widgets/follow_up_options_sheet.dart';
import 'widgets/reschedule_follow_up_sheet.dart';

class FollowUpDetailsScreen extends StatelessWidget {
  final String followUpId;

  const FollowUpDetailsScreen({
    super.key,
    required this.followUpId,
  });

  void _openActionSheet(
    BuildContext context, {
    required String leadId,
    required String leadName,
    required String scheduleText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FollowUpOptionsSheet(
        leadId: leadId,
        leadName: leadName,
        currentSchedule: scheduleText,
      ),
    );
  }

  void _openCompleteSheet(BuildContext context, String leadName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompleteFollowUpSheet(leadName: leadName),
    );
  }

  void _openRescheduleSheet(
    BuildContext context, {
    required String leadName,
    required String scheduleText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RescheduleFollowUpSheet(
        currentSchedule: scheduleText,
        leadName: leadName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isWhatsAppMethod = followUpId == 'fu_002';

    const leadId = 'lead_1';
    final leadName = isWhatsAppMethod ? 'Ocean Nest Hotel' : 'Sea Pearl Resort';
    final leadStatus = isWhatsAppMethod ? 'Contacted' : 'Follow-up';
    final leadStatusColor =
        isWhatsAppMethod ? AppColors.leadContacted : AppColors.warning;

    final methodTitle = isWhatsAppMethod ? 'WhatsApp' : 'Call';
    final methodIcon = isWhatsAppMethod
        ? CupertinoIcons.chat_bubble_fill
        : CupertinoIcons.phone_fill;
    const methodIconColor = AppColors.success;

    final scheduledText = isWhatsAppMethod ? 'Today' : 'Yesterday';
    final scheduledTime = isWhatsAppMethod ? '9:00 AM' : '4:00 PM';
    final overdueNote = isWhatsAppMethod ? 'Overdue by 3h' : 'Overdue by 20h';

    final purpose = isWhatsAppMethod
        ? 'Follow-up after initial call'
        : 'Pricing discussion';

    final assigneeInitials = isWhatsAppMethod ? 'Y' : 'SA';
    final assigneeName = isWhatsAppMethod ? 'Yeapas' : 'Shahina Akter';

    final contactInitials = isWhatsAppMethod ? 'R' : 'K';
    final contactName = isWhatsAppMethod ? 'Rafiq Islam' : 'Karim Ahmed';
    final contactPhone = isWhatsAppMethod ? '01711-222222' : '01711-111111';

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Follow-up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openActionSheet(
                  context,
                  leadId: leadId,
                  leadName: leadName,
                  scheduleText: '$scheduledText · $scheduledTime',
                ),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      overdueNote,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color:
                                      methodIconColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  methodIcon,
                                  color: methodIconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Method',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nec.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    methodTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled',
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scheduledText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            scheduledTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purpose',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      purpose,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: NecAvatar(
                        initials: assigneeInitials,
                        size: 38,
                      ),
                      title: Text(
                        'Assigned To',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      subtitle: Text(
                        assigneeName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.3),
                      indent: 16,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            contactInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Contact Person',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contactName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contactPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AUTOMATED SMS NOTIFICATION',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: nec.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/auto-sms-settings'),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6355F6),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(CupertinoIcons.chevron_right,
                                size: 12, color: Color(0xFF6355F6)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: AutoSmsSettingsStore.instance,
                builder: (context, _) {
                  final smsStore = AutoSmsSettingsStore.instance;
                  final isSmsActive = smsStore.isAutoSmsEnabled;
                  final smsMessage = smsStore.formatTemplate(
                    clientName: contactName.isNotEmpty ? contactName : leadName,
                    date: scheduledText,
                    time: scheduledTime,
                    purpose: purpose,
                    repName: assigneeName,
                  );

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSmsActive
                            ? const Color(0xFF6355F6).withValues(alpha: 0.35)
                            : nec.separator.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: isSmsActive
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF6355F6),
                                          Color(0xFF7C6FF7)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSmsActive
                                    ? null
                                    : nec.separator.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                boxShadow: isSmsActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6355F6)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                CupertinoIcons.chat_bubble_text_fill,
                                size: 16,
                                color: isSmsActive
                                    ? Colors.white
                                    : nec.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-SMS Reminder',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6355F6)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF6355F6)
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          smsStore.triggerTiming,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6355F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.person_crop_circle,
                                          size: 12, color: nec.textTertiary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'To: $contactName ($contactPhone)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: nec.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSmsActive
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : nec.separator.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSmsActive
                                          ? AppColors.success
                                          : nec.textTertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isSmsActive ? 'Active' : 'Off',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSmsActive
                                          ? AppColors.success
                                          : nec.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF16161D)
                                : const Color(0xFFF6F8FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                      CupertinoIcons.checkmark_shield_fill,
                                      size: 12,
                                      color: Color(0xFF6355F6)),
                                  const SizedBox(width: 5),
                                  Text(
                                    smsStore.senderId,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Simulated Queue',
                                    style: TextStyle(
                                        fontSize: 10, color: nec.textTertiary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                smsMessage,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              smsStore.recordSimulatedDispatch();
                              NecToast.show(
                                context,
                                message:
                                    'Simulated Auto-SMS sent to $contactPhone',
                                type: NecToastType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6355F6),
                                    Color(0xFF4F46E5)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6355F6)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.paperplane_fill,
                                        size: 14, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send Test SMS Now',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'LEAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_2,
                      color: AppColors.brandLight,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    leadName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: leadStatusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: leadStatusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                leadStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: leadStatusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: () => context.push('/leads/$leadId'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    NecToast.show(
                      context,
                      message: isWhatsAppMethod
                          ? 'Opening WhatsApp for $contactName...'
                          : 'Calling $contactName ($contactPhone)...',
                      type: NecToastType.info,
                    );
                  },
                  icon: Icon(
                    isWhatsAppMethod
                        ? CupertinoIcons.chat_bubble_fill
                        : CupertinoIcons.phone_fill,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    isWhatsAppMethod ? 'Open WhatsApp' : 'Call $contactName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nec.brand,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _openCompleteSheet(context, leadName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nec.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: nec.separator.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _openRescheduleSheet(
                          context,
                          leadName: leadName,
                          scheduleText: '$scheduledText · $scheduledTime',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nec.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: nec.separator.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Reschedule',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
