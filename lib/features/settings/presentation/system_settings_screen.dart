import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/system_settings_store.dart';
import '../domain/models/system_settings.dart';
import 'widgets/operations_settings_app_bar.dart';
import 'widgets/system_setting_choice_sheet.dart';
import 'widgets/system_settings_group.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _settings = SystemSettingsStore.instance;

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  Future<void> _apply(SystemSettings Function(SystemSettings) transform) async {
    final saved = await _settings.update(transform);
    if (!mounted || saved) return;
    NecToast.show(
      context,
      message: 'Could not save this setting. Please try again.',
      type: NecToastType.error,
    );
  }

  void _showChoices({
    required String title,
    required String selectedValue,
    required List<SystemSettingChoice> choices,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SystemSettingChoiceSheet(
        title: title,
        selectedValue: selectedValue,
        choices: choices,
        onSelected: onSelected,
      ),
    );
  }

  Widget _heading(NecColors nec, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
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
          title: 'System Settings', centerTitle: true),
      body: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          final value = _settings.value;
          final ready = _settings.ready;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 100),
            children: [
              _heading(nec, 'ORGANIZATION'),
              SystemSettingsGroup(
                children: [
                  SystemSettingsRow(
                    title: 'Organization Information',
                    value: value.organizationName,
                    onTap: ready
                        ? () => context.push('/system-settings/organization')
                        : null,
                  ),
                  const SystemSettingsRow(
                    title: 'Branding',
                    subtitle: 'NEC TEAM · by NEONECY',
                    locked: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _heading(nec, 'APP DEFAULTS'),
              SystemSettingsGroup(
                children: [
                  SystemSettingsRow(
                    title: 'Default Lead Priority',
                    value: value.defaultLeadPriority,
                    onTap: ready
                        ? () => _showChoices(
                              title: 'Default Lead Priority',
                              selectedValue: value.defaultLeadPriority,
                              choices: const [
                                SystemSettingChoice(
                                    value: 'Low',
                                    label: 'Low',
                                    color: AppColors.neutral),
                                SystemSettingChoice(
                                    value: 'Normal',
                                    label: 'Normal',
                                    color: AppColors.brandLight),
                                SystemSettingChoice(
                                    value: 'High',
                                    label: 'High',
                                    color: AppColors.warning),
                                SystemSettingChoice(
                                    value: 'Urgent',
                                    label: 'Urgent',
                                    color: AppColors.error),
                              ],
                              onSelected: (priority) => _apply(
                                (settings) => settings.copyWith(
                                    defaultLeadPriority: priority),
                              ),
                            )
                        : null,
                  ),
                  SystemSettingsRow(
                    title: 'Auto-assign Leads',
                    subtitle:
                        'Automatically assign new leads to available sales staff',
                    switchValue: value.autoAssignLeads,
                    onChanged: ready
                        ? (enabled) => _apply(
                              (settings) =>
                                  settings.copyWith(autoAssignLeads: enabled),
                            )
                        : null,
                  ),
                  SystemSettingsRow(
                    title: 'Task Review Stage',
                    subtitle: 'Enable review before tasks are marked complete',
                    switchValue: value.taskReviewStage,
                    onChanged: ready
                        ? (enabled) => _apply(
                              (settings) =>
                                  settings.copyWith(taskReviewStage: enabled),
                            )
                        : null,
                  ),
                  SystemSettingsRow(
                    title: 'Issue Testing Stage',
                    subtitle: 'Enable testing stage before issues are resolved',
                    switchValue: value.issueTestingStage,
                    onChanged: ready
                        ? (enabled) => _apply(
                              (settings) =>
                                  settings.copyWith(issueTestingStage: enabled),
                            )
                        : null,
                  ),
                  SystemSettingsRow(
                    title: 'Require Lost Reason',
                    subtitle: 'Require a reason when marking a lead as Lost',
                    switchValue: value.requireLostReason,
                    onChanged: ready
                        ? (enabled) => _apply(
                              (settings) =>
                                  settings.copyWith(requireLostReason: enabled),
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _heading(nec, 'TIMEZONE & LOCALE'),
              SystemSettingsGroup(
                children: [
                  SystemSettingsRow(
                    title: 'Organization Timezone',
                    value:
                        '${value.timezone.label}\n(${value.timezone.offset})',
                    onTap: ready
                        ? () => _showChoices(
                              title: 'Organization Timezone',
                              selectedValue: value.timezone.name,
                              choices: [
                                for (final timezone
                                    in OrganizationTimezone.values)
                                  SystemSettingChoice(
                                    value: timezone.name,
                                    label: timezone.label,
                                    subtitle: timezone.offset,
                                  ),
                              ],
                              onSelected: (name) =>
                                  _apply((settings) => settings.copyWith(
                                        timezone: OrganizationTimezone.values
                                            .firstWhere(
                                                (zone) => zone.name == name),
                                      )),
                            )
                        : null,
                  ),
                  SystemSettingsRow(
                    title: 'Date Format',
                    value: value.dateFormat.label,
                    onTap: ready
                        ? () => _showChoices(
                              title: 'Date Format',
                              selectedValue: value.dateFormat.name,
                              choices: [
                                for (final format
                                    in OrganizationDateFormat.values)
                                  SystemSettingChoice(
                                      value: format.name, label: format.label),
                              ],
                              onSelected: (name) =>
                                  _apply((settings) => settings.copyWith(
                                        dateFormat: OrganizationDateFormat
                                            .values
                                            .firstWhere((format) =>
                                                format.name == name),
                                      )),
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _heading(nec, 'SECURITY POLICY'),
              const SystemSettingsGroup(
                children: [
                  SystemSettingsRow(
                    title: 'Session Timeout',
                    subtitle: 'Contact Super Admin to modify session policy',
                    locked: true,
                  ),
                  SystemSettingsRow(
                    title: 'Password Policy',
                    subtitle:
                        'Contact Super Admin to modify password requirements',
                    locked: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.035),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.info_circle,
                            size: 15, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Important',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'System settings affect all users across NEC TEAM. Changes '
                      'to defaults apply to new records only — existing records '
                      'are not modified.',
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: nec.textSecondary),
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
}
