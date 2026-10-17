import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_alert_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../more/data/notification_store.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'widgets/preference_toggle_row.dart';
import 'widgets/notification_tone_sheet.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _loading = true, _saving = false;
  String? _loadError;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _leadAssigned = true;
  bool _newLead = true;
  bool _leadReassigned = true;

  bool _dueReminder = true;
  bool _overdue = true;

  bool _upcomingVisit = true;
  bool _visitChanged = true;

  bool _taskAssigned = true;
  bool _taskDue = true;
  bool _taskComments = true;

  bool _issueAssigned = true;
  bool _issueUpdated = true;
  bool _issueResolved = true;

  @override
  void initState() {
    super.initState();
    _loadAlertSettings();
    _loadPreferences();
  }

  void _loadAlertSettings() async {
    await NotificationAlertManager.instance.initialize();
    if (mounted) {
      setState(() {
        _soundEnabled = NotificationAlertManager.instance.soundEnabled;
        _vibrationEnabled = NotificationAlertManager.instance.vibrationEnabled;
      });
    }
  }

  void _toggleSound(bool val) {
    setState(() => _soundEnabled = val);
    NotificationAlertManager.instance.setSoundEnabled(val);
    if (val) {
      NotificationAlertManager.instance.triggerAlert(forceSound: true);
    }
  }

  void _toggleVibration(bool val) {
    setState(() => _vibrationEnabled = val);
    NotificationAlertManager.instance.setVibrationEnabled(val);
    if (val) {
      NotificationAlertManager.instance.triggerAlert(forceVibration: true);
    }
  }

  Future<void> _loadPreferences() async {
    final token = AuthSession.instance.accessToken;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await NotificationStore.instance.getPreferences();
      if (token != AuthSession.instance.accessToken) return;
      final groups = res['event_groups'];
      if (groups is! List) {
        throw const FormatException('Invalid notification preferences.');
      }
      if (mounted) {
        final eventMap = <String, bool>{};
        for (final g in groups) {
          if (g is Map && g['events'] is List) {
            for (final ev in g['events'] as List) {
              if (ev is Map && ev['key'] != null && ev['enabled'] is bool) {
                eventMap[ev['key'].toString()] = ev['enabled'] as bool;
              }
            }
          }
        }
        setState(() {
          if (eventMap.containsKey('lead.assigned')) {
            _leadAssigned = eventMap['lead.assigned']!;
          }
          if (eventMap.containsKey('lead.created')) {
            _newLead = eventMap['lead.created']!;
          }
          if (eventMap.containsKey('lead.updated')) {
            _leadReassigned = eventMap['lead.updated']!;
          }
          if (eventMap.containsKey('followups.reminder')) {
            _dueReminder = eventMap['followups.reminder']!;
          }
          if (eventMap.containsKey('followups.overdue')) {
            _overdue = eventMap['followups.overdue']!;
          }
          if (eventMap.containsKey('visits.scheduled')) {
            _upcomingVisit = eventMap['visits.scheduled']!;
          }
          if (eventMap.containsKey('visits.rescheduled')) {
            _visitChanged = eventMap['visits.rescheduled']!;
          }
          if (eventMap.containsKey('tasks.assigned')) {
            _taskAssigned = eventMap['tasks.assigned']!;
          }
          if (eventMap.containsKey('tasks.reminder')) {
            _taskDue = eventMap['tasks.reminder']!;
          }
          if (eventMap.containsKey('tasks.comment_added')) {
            _taskComments = eventMap['tasks.comment_added']!;
          }
          if (eventMap.containsKey('issues.assigned')) {
            _issueAssigned = eventMap['issues.assigned']!;
          }
          if (eventMap.containsKey('issues.updated')) {
            _issueUpdated = eventMap['issues.updated']!;
          }
          if (eventMap.containsKey('issues.resolved')) {
            _issueResolved = eventMap['issues.resolved']!;
          }
        });
      }
    } catch (_) {
      if (mounted) _loadError = 'Unable to load notification preferences.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onToggle(String key, bool value, void Function() apply) async {
    if (_loading || _saving || _loadError != null) return;
    final token = AuthSession.instance.accessToken;
    setState(() => _saving = true);
    try {
      await NotificationStore.instance.updatePreferences(events: {key: value});
      if (mounted && token == AuthSession.instance.accessToken) apply();
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to save this preference. Please retry.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
                  'Notifications',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_loadError!),
                  TextButton(
                      onPressed: _loadPreferences, child: const Text('Retry'))
                ]))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage your notification alerts.',
                          style: TextStyle(
                            fontSize: 14,
                            color: nec.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSectionHeader(context, 'SOUND & VIBRATION'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Notification Sound',
                                subtitle:
                                    'Play tone (${NotificationAlertManager.instance.selectedTone.title})',
                                value: _soundEnabled,
                                onChanged: _toggleSound,
                              ),
                              ListTile(
                                title: Text(
                                  'Notification Tone',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _soundEnabled
                                        ? nec.textPrimary
                                        : nec.textTertiary,
                                  ),
                                ),
                                subtitle: Text(
                                  _soundEnabled
                                      ? NotificationAlertManager
                                          .instance.selectedTone.subtitle
                                      : 'Sound is currently muted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nec.textTertiary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      NotificationAlertManager
                                          .instance.selectedTone.title
                                          .split(' (')
                                          .first,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _soundEnabled
                                            ? nec.textTertiary
                                            : nec.textTertiary
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: _soundEnabled
                                          ? nec.textTertiary
                                          : nec.textTertiary
                                              .withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                                onTap: _soundEnabled
                                    ? () async {
                                        await NotificationToneSheet.show(
                                            context);
                                        if (mounted) setState(() {});
                                      }
                                    : null,
                              ),
                              Divider(
                                height: 1,
                                indent: 16,
                                color: nec.separator.withValues(alpha: 0.3),
                              ),
                              PreferenceToggleRow(
                                title: 'Vibrate with Sound',
                                subtitle: 'Vibrate device on incoming alerts',
                                value: _vibrationEnabled,
                                onChanged: _toggleVibration,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSectionHeader(context, 'LEADS'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Lead Assigned',
                                subtitle: 'When a lead is assigned to you',
                                value: _leadAssigned,
                                onChanged: (v) => _onToggle('lead.assigned', v,
                                    () => setState(() => _leadAssigned = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'New Lead',
                                subtitle:
                                    'When a new lead is created in your territory',
                                value: _newLead,
                                onChanged: (v) => _onToggle('lead.created', v,
                                    () => setState(() => _newLead = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Lead Reassigned',
                                subtitle:
                                    'When one of your leads is reassigned',
                                value: _leadReassigned,
                                onChanged: (v) => _onToggle('lead.updated', v,
                                    () => setState(() => _leadReassigned = v)),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader(context, 'FOLLOW-UPS'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Due Reminder',
                                subtitle:
                                    'Reminder when a follow-up is approaching',
                                value: _dueReminder,
                                onChanged: (v) => _onToggle(
                                    'followups.reminder',
                                    v,
                                    () => setState(() => _dueReminder = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Overdue',
                                subtitle: 'When a follow-up becomes overdue',
                                value: _overdue,
                                onChanged: (v) => _onToggle('followups.overdue',
                                    v, () => setState(() => _overdue = v)),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader(context, 'VISITS'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Upcoming Visit',
                                subtitle: 'Reminder before a scheduled visit',
                                value: _upcomingVisit,
                                onChanged: (v) => _onToggle(
                                    'visits.scheduled',
                                    v,
                                    () => setState(() => _upcomingVisit = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Visit Changed',
                                subtitle:
                                    'When a visit is rescheduled or cancelled',
                                value: _visitChanged,
                                onChanged: (v) => _onToggle(
                                    'visits.rescheduled',
                                    v,
                                    () => setState(() => _visitChanged = v)),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader(context, 'TASKS'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Task Assigned',
                                subtitle: 'When a task is assigned to you',
                                value: _taskAssigned,
                                onChanged: (v) => _onToggle('tasks.assigned', v,
                                    () => setState(() => _taskAssigned = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Task Due',
                                subtitle: 'When a task due date is approaching',
                                value: _taskDue,
                                onChanged: (v) => _onToggle('tasks.reminder', v,
                                    () => setState(() => _taskDue = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Comments',
                                subtitle: 'When someone comments on your task',
                                value: _taskComments,
                                onChanged: (v) => _onToggle(
                                    'tasks.comment_added',
                                    v,
                                    () => setState(() => _taskComments = v)),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader(context, 'ISSUES'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Issue Assigned',
                                subtitle: 'When an issue is assigned to you',
                                value: _issueAssigned,
                                onChanged: (v) => _onToggle(
                                    'issues.assigned',
                                    v,
                                    () => setState(() => _issueAssigned = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Issue Updated',
                                subtitle:
                                    'When an issue you are involved with is updated',
                                value: _issueUpdated,
                                onChanged: (v) => _onToggle('issues.updated', v,
                                    () => setState(() => _issueUpdated = v)),
                              ),
                              PreferenceToggleRow(
                                title: 'Issue Resolved',
                                subtitle: 'When a related issue is resolved',
                                value: _issueResolved,
                                onChanged: (v) => _onToggle(
                                    'issues.resolved',
                                    v,
                                    () => setState(() => _issueResolved = v)),
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader(context, 'SYSTEM'),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: const Column(
                            children: [
                              PreferenceToggleRow(
                                title: 'Access & Permissions',
                                subtitle:
                                    'When your role or permissions change',
                                note: 'Required by system policy',
                                value: true,
                                onChanged: null,
                              ),
                              PreferenceToggleRow(
                                title: 'System Updates',
                                subtitle: 'Important NEC TEAM service notices',
                                note: 'Required by system policy',
                                value: true,
                                onChanged: null,
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
}
