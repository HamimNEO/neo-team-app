import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/preference_toggle_row.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
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
      body: SafeArea(
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
                      onChanged: (v) => setState(() => _leadAssigned = v),
                    ),
                    PreferenceToggleRow(
                      title: 'New Lead',
                      subtitle: 'When a new lead is created in your territory',
                      value: _newLead,
                      onChanged: (v) => setState(() => _newLead = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Lead Reassigned',
                      subtitle: 'When one of your leads is reassigned',
                      value: _leadReassigned,
                      onChanged: (v) => setState(() => _leadReassigned = v),
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
                      subtitle: 'Reminder when a follow-up is approaching',
                      value: _dueReminder,
                      onChanged: (v) => setState(() => _dueReminder = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Overdue',
                      subtitle: 'When a follow-up becomes overdue',
                      value: _overdue,
                      onChanged: (v) => setState(() => _overdue = v),
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
                      onChanged: (v) => setState(() => _upcomingVisit = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Visit Changed',
                      subtitle: 'When a visit is rescheduled or cancelled',
                      value: _visitChanged,
                      onChanged: (v) => setState(() => _visitChanged = v),
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
                      onChanged: (v) => setState(() => _taskAssigned = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Task Due',
                      subtitle: 'When a task due date is approaching',
                      value: _taskDue,
                      onChanged: (v) => setState(() => _taskDue = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Comments',
                      subtitle: 'When someone comments on your task',
                      value: _taskComments,
                      onChanged: (v) => setState(() => _taskComments = v),
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
                      onChanged: (v) => setState(() => _issueAssigned = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Issue Updated',
                      subtitle:
                          'When an issue you are involved with is updated',
                      value: _issueUpdated,
                      onChanged: (v) => setState(() => _issueUpdated = v),
                    ),
                    PreferenceToggleRow(
                      title: 'Issue Resolved',
                      subtitle: 'When a related issue is resolved',
                      value: _issueResolved,
                      onChanged: (v) => setState(() => _issueResolved = v),
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
                      subtitle: 'When your role or permissions change',
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
