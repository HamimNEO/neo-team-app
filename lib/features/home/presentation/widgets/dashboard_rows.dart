import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/staff_access_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../leads/data/lead_store.dart';
import '../../../tasks/data/work_item_store.dart';
import '../../../tasks/domain/models/work_item.dart';

class DashboardRows {
  static bool open(WorkItem item) => ![
        'completed',
        'done',
        'cancelled',
        'resolved',
        'closed'
      ].contains(item.status.toLowerCase());

  static String route(WorkItem item) => switch (item.type) {
        'followup' => '/follow-up-details/${item.id}',
        'visit' => '/visit-details/${item.id}',
        'issue' => '/issues',
        _ => '/tasks/${item.id}',
      };

  static bool permitted(WorkItem item, bool staff) =>
      !staff ||
      StaffAccessStore.instance.allows(switch (item.type) {
        'followup' => StaffPermission.followUps,
        'visit' => StaffPermission.visits,
        'issue' => StaffPermission.issues,
        _ => StaffPermission.tasks,
      });

  static List<Map<String, dynamic>> attention({bool staff = false}) {
    final now = DateTime.now();
    return [
      for (final item in WorkItemStore.instance.items)
        if (open(item) &&
            permitted(item, staff) &&
            item.scheduledAt != null &&
            item.scheduledAt!.isBefore(now))
          {
            'id': item.id,
            'title': item.leadName ?? item.title,
            'subtitle':
                '${item.type == 'followup' ? 'Follow-up' : item.type == 'visit' ? 'Visit' : 'Task'} overdue · ${now.difference(item.scheduledAt!).inHours}h',
            'isOverdue': true,
            'icon': CupertinoIcons.arrow_turn_down_left,
            'route': route(item)
          },
      if (!staff)
        for (final lead in LeadStore.instance.leads)
          if (lead.assignedEmployeeId == null &&
              !['Won', 'Lost'].contains(lead.status))
            {
              'id': lead.id,
              'title': lead.company,
              'subtitle': 'Unassigned · ${lead.status}',
              'isOverdue': false,
              'icon': CupertinoIcons.person_2,
              'route': '/leads/${lead.id}'
            },
    ];
  }

  static List<Map<String, dynamic>> today({bool staff = false}) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final items = WorkItemStore.instance.items
        .where((i) =>
            open(i) &&
            permitted(i, staff) &&
            i.scheduledAt != null &&
            i.scheduledAt!.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    return [
      for (final item in items)
        {
          'time': item.scheduledAt!.isBefore(now)
              ? 'Late'
              : DateFormat.jm().format(item.scheduledAt!.toLocal()),
          'title': item.leadName ?? item.title,
          'type':
              '${item.type == 'visit' ? 'Site Visit' : item.type == 'followup' ? 'Follow-up' : 'Task'} · ${item.title}',
          'isLate': item.scheduledAt!.isBefore(now),
          'route': route(item),
        }
    ];
  }

  static List<Map<String, dynamic>> leadActions() => [
        for (final lead in LeadStore.instance.leads)
          if (!['Won', 'Lost'].contains(lead.status) &&
              (lead.nextAction != null || lead.status == 'Follow-up'))
            {
              'id': lead.id,
              'title': lead.company,
              'subtitle': lead.nextAction == null
                  ? 'No next action scheduled'
                  : '${lead.nextActionNote ?? 'Next action'} · ${DateFormat('MMM d, h:mm a').format(lead.nextAction!.toLocal())}',
              'badgeText': lead.status,
              'badgeColor': AppColors.warning,
              'route': '/leads/${lead.id}'
            },
      ];
}

class SectionEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SectionEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final auraBg = isDark ? const Color(0xFF132338) : const Color(0xFFEFF6FF);
    const accentColor = Color(0xFF007AFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : nec.separator.withValues(alpha: 0.18),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: auraBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 32,
                      color: accentColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 28,
                  child: Container(
                    width: 6,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 28,
                  child: Container(
                    width: 6,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: nec.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: nec.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionEmptyCard(
      icon: CupertinoIcons.shield_fill,
      title: 'You’re all caught up',
      subtitle: message,
    );
  }
}
