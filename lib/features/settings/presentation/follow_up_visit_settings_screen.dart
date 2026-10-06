import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auto_sms_settings_store.dart';
import '../data/follow_up_visit_settings_store.dart';
import '../domain/models/operation_option.dart';
import 'widgets/add_operation_option_sheet.dart';
import 'widgets/operation_options_card.dart';
import 'widgets/operations_settings_app_bar.dart';

class FollowUpVisitSettingsScreen extends StatefulWidget {
  const FollowUpVisitSettingsScreen({super.key});

  @override
  State<FollowUpVisitSettingsScreen> createState() =>
      _FollowUpVisitSettingsScreenState();
}

class _FollowUpVisitSettingsScreenState
    extends State<FollowUpVisitSettingsScreen> {
  final _settings = FollowUpVisitSettingsStore.instance;

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  void _showAddSheet(OperationOptionGroup group) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddOperationOptionSheet(group: group, settings: _settings),
    );
  }

  Widget _heading(NecColors nec, String title) => Padding(
        padding: const EdgeInsets.only(left: 0, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w600,
            color: nec.textTertiary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: const OperationsSettingsAppBar(
        title: 'Follow-up & Visit Settings',
        centerTitle: false,
      ),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          children: [
            _heading(nec, 'FOLLOW-UPS'),
            OperationOptionsCard(
              settings: _settings,
              groups: const [
                OperationOptionGroup.followUpMethods,
                OperationOptionGroup.followUpResults,
              ],
              onAdd: _showAddSheet,
            ),
            const SizedBox(height: 24),
            _heading(nec, 'AUTOMATED SMS NOTIFICATIONS'),
            AnimatedBuilder(
              animation: AutoSmsSettingsStore.instance,
              builder: (context, _) {
                final smsStore = AutoSmsSettingsStore.instance;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: nec.separator.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6355F6)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                CupertinoIcons.chat_bubble_text_fill,
                                color: Color(0xFF6355F6),
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-SMS on Follow-up',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary),
                                ),
                                Text(
                                  smsStore.isAutoSmsEnabled
                                      ? 'Enabled · ${smsStore.triggerTiming}'
                                      : 'Disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: smsStore.isAutoSmsEnabled
                                        ? const Color(0xFF6355F6)
                                        : nec.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: smsStore.isAutoSmsEnabled,
                            onChanged: (val) => smsStore.toggleAutoSms(val),
                            activeTrackColor: const Color(0xFF6355F6),
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Automatically dispatch branded SMS reminders to client contacts when follow-up dates and times approach.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => context.push('/auto-sms-settings'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'Configure Templates, Timing & Test SMS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: nec.brand,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: nec.brand),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _heading(nec, 'VISITS'),
            OperationOptionsCard(
              settings: _settings,
              groups: const [
                OperationOptionGroup.visitPurposes,
                OperationOptionGroup.visitOutcomes,
              ],
              onAdd: _showAddSheet,
            ),
            const SizedBox(height: 20),
            Text(
              'System-defined items cannot be disabled. Custom items can be '
              'toggled or removed. Historical records are always preserved.',
              style:
                  TextStyle(fontSize: 12, height: 1.5, color: nec.textTertiary),
            ),
            const SizedBox(height: 6),
            Text(
              'Swipe left on a custom item to remove it.',
              style:
                  TextStyle(fontSize: 12, height: 1.5, color: nec.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
