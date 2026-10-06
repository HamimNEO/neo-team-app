import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/auto_sms_settings_store.dart';

class AutoSmsSettingsScreen extends StatefulWidget {
  const AutoSmsSettingsScreen({super.key});

  @override
  State<AutoSmsSettingsScreen> createState() => _AutoSmsSettingsScreenState();
}

class _AutoSmsSettingsScreenState extends State<AutoSmsSettingsScreen> {
  final _store = AutoSmsSettingsStore.instance;
  late TextEditingController _templateController;
  late TextEditingController _phoneController;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _store.load();
    _templateController = TextEditingController(text: _store.smsTemplate);
    _phoneController = TextEditingController(text: _store.testPhoneNumber);

    _store.addListener(_onStoreUpdate);
  }

  void _onStoreUpdate() {
    if (_templateController.text != _store.smsTemplate) {
      _templateController.text = _store.smsTemplate;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    _templateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final text = _templateController.text;
    final selection = _templateController.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, token);
      _templateController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + token.length),
      );
    } else {
      _templateController.text = '$text $token';
    }
    _store.setTemplate(_templateController.text);
  }

  Future<void> _sendTestSms() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      NecToast.show(context,
          message: 'Please enter a valid phone number',
          type: NecToastType.error);
      return;
    }

    setState(() => _isSendingTest = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _store.recordSimulatedDispatch();
    setState(() => _isSendingTest = false);

    NecToast.show(
      context,
      message: 'Simulated Auto-SMS sent successfully to $phone',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, size: 18, color: nec.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Automated SMS Settings',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: nec.textPrimary),
        ),
      ),
      body: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final isEnabled = _store.isAutoSmsEnabled;
          final previewText = _store.formatTemplate(
            clientName: 'Ocean Blue Hotel',
            date: 'Today',
            time: '4:00 PM',
            purpose: 'Contract Finalization',
            repName: 'Shahina Akter',
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF241C48), const Color(0xFF161524)]
                        : [const Color(0xFFF3F0FF), const Color(0xFFE8E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6355F6)
                        .withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6355F6)
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6355F6), Color(0xFF7C6FF7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6355F6)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(CupertinoIcons.chat_bubble_2_fill,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto SMS Engine',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: nec.textPrimary),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? AppColors.success
                                          : AppColors.neutral,
                                      shape: BoxShape.circle,
                                      boxShadow: isEnabled
                                          ? [
                                              BoxShadow(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isEnabled
                                        ? 'Active (Simulated Mode)'
                                        : 'Inactive / Paused',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isEnabled
                                          ? AppColors.success
                                          : nec.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6355F6), Color(0xFF4F46E5)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6355F6)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_store.totalDispatched} Sent',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'When a follow-up approaches its scheduled time, NEC TEAM automatically dispatches a branded SMS reminder to the client or assigned executive.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: nec.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _store.toggleAutoSms(!isEnabled),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isEnabled
                            ? const Color(0xFF6355F6).withValues(alpha: 0.4)
                            : nec.separator.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? const Color(0xFF6355F6)
                                    .withValues(alpha: 0.12)
                                : nec.separator.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEnabled
                                ? CupertinoIcons.bell_fill
                                : CupertinoIcons.bell_slash,
                            size: 20,
                            color: isEnabled
                                ? const Color(0xFF6355F6)
                                : nec.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Follow-Up Auto-SMS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Automatically trigger SMS notifications on follow-ups',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isEnabled,
                          onChanged: (val) => _store.toggleAutoSms(val),
                          activeTrackColor: const Color(0xFF6355F6),
                          activeThumbColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(nec, 'DISPATCH TRIGGER TIMING'),
              Container(
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: nec.separator.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: AutoSmsSettingsStore.timingOptions.map((timing) {
                      final isSelected = _store.triggerTiming == timing;
                      final isLast =
                          timing == AutoSmsSettingsStore.timingOptions.last;

                      return InkWell(
                        onTap: isEnabled
                            ? () => _store.setTriggerTiming(timing)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: isSelected && isEnabled
                                ? const Color(0xFF6355F6)
                                    .withValues(alpha: isDark ? 0.12 : 0.06)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isLast
                                    ? Colors.transparent
                                    : nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected && isEnabled
                                    ? const Color(0xFF6355F6)
                                    : nec.textTertiary,
                                size: 21,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Text(
                                  timing,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isEnabled
                                        ? nec.textPrimary
                                        : nec.textTertiary,
                                  ),
                                ),
                              ),
                              if (timing == '15 minutes before')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6355F6)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF6355F6)
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6355F6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(nec, 'TARGET RECIPIENT'),
              Container(
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: nec.separator.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children:
                        AutoSmsSettingsStore.recipientOptions.map((target) {
                      final isSelected = _store.recipientTarget == target;
                      final isLast =
                          target == AutoSmsSettingsStore.recipientOptions.last;

                      IconData targetIcon = CupertinoIcons.person_crop_circle;
                      if (target.contains('Representative')) {
                        targetIcon = CupertinoIcons.person_badge_plus;
                      } else if (target.contains('Both')) {
                        targetIcon = CupertinoIcons.person_2;
                      }

                      return InkWell(
                        onTap: isEnabled
                            ? () => _store.setRecipientTarget(target)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: isSelected && isEnabled
                                ? const Color(0xFF6355F6)
                                    .withValues(alpha: isDark ? 0.12 : 0.06)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isLast
                                    ? Colors.transparent
                                    : nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: isSelected && isEnabled
                                    ? const Color(0xFF6355F6)
                                    : nec.textTertiary,
                                size: 21,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                targetIcon,
                                size: 18,
                                color: isSelected && isEnabled
                                    ? const Color(0xFF6355F6)
                                    : nec.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  target,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isEnabled
                                        ? nec.textPrimary
                                        : nec.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(nec, 'SMS TEMPLATE CONFIGURATION'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: nec.separator.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6355F6)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.checkmark_seal_fill,
                                        size: 11, color: Color(0xFF6355F6)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Alpha Sender',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6355F6)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _store.senderId,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            _store.resetToDefaultTemplate();
                            _templateController.text = _store.smsTemplate;
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.arrow_counterclockwise,
                                    size: 12, color: Color(0xFF6355F6)),
                                SizedBox(width: 4),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6355F6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _templateController,
                      enabled: isEnabled,
                      maxLines: 4,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.5, color: nec.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B1B22)
                            : const Color(0xFFF8F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: nec.separator.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF6355F6), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onChanged: (val) => _store.setTemplate(val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_templateController.text.length} characters',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: nec.textTertiary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: nec.separator.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${((_templateController.text.length / 160).floor()) + 1} SMS segment(s)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: nec.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap placeholder to insert:',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          AutoSmsSettingsStore.availableTokens.map((token) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isEnabled ? () => _insertToken(token) : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF6355F6)
                                        .withValues(alpha: 0.14)
                                    : const Color(0xFF6355F6)
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF6355F6)
                                      .withValues(alpha: 0.28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.add,
                                    size: 11,
                                    color: Color(0xFF6355F6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    token,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6355F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(nec, 'LIVE CLIENT SMS PREVIEW'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141419)
                      : const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: nec.separator.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6355F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                              CupertinoIcons.device_phone_portrait,
                              size: 13,
                              color: Color(0xFF6355F6)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'From: ${_store.senderId}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.checkmark_seal_fill,
                                  size: 12, color: Color(0xFF6355F6)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today, 3:45 PM',
                          style:
                              TextStyle(fontSize: 11, color: nec.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF24242C) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(5),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        previewText,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.48,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Simulated Delivery',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: nec.textTertiary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(CupertinoIcons.checkmark_alt,
                              size: 12, color: AppColors.success),
                          const Icon(CupertinoIcons.checkmark_alt,
                              size: 12, color: AppColors.success),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _sectionHeader(nec, 'SIMULATION & TEST DISPATCH'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: nec.separator.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulate Auto-SMS Dispatch',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test the auto SMS engine by sending a live simulated alert to any mobile number.',
                      style: TextStyle(
                          fontSize: 12, height: 1.4, color: nec.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B1B22)
                                  : const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: nec.separator.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(CupertinoIcons.phone_fill,
                                      size: 16, color: Color(0xFF6355F6)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textPrimary),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: '+880 1711-223344',
                                      hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: nec.textTertiary),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSendingTest ? null : _sendTestSms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6355F6), Color(0xFF4F46E5)],
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
                              height: 46,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: _isSendingTest
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.paperplane_fill,
                                            size: 14, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Send Test',
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(NecColors nec, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w700,
          color: nec.textTertiary,
        ),
      ),
    );
  }
}
