import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

class LeadStatusConfig {
  final Color deepColor;
  final Color lightBg;
  final IconData icon;

  const LeadStatusConfig({
    required this.deepColor,
    required this.lightBg,
    required this.icon,
  });

  static LeadStatusConfig fromStatus(String status) {
    final clean = status.trim().toLowerCase().replaceAll('_', ' ');
    if (clean == 'new' || clean == 'new lead') {
      return const LeadStatusConfig(
        deepColor: Color(0xFF0284C7),
        lightBg: Color(0xFFE0F2FE),
        icon: CupertinoIcons.sparkles,
      );
    } else if (clean == 'follow-up' ||
        clean == 'followup' ||
        clean == 'follow up') {
      return const LeadStatusConfig(
        deepColor: Color(0xFFD97706),
        lightBg: Color(0xFFFEF3C7),
        icon: CupertinoIcons.clock_fill,
      );
    } else if (clean == 'contacted') {
      return const LeadStatusConfig(
        deepColor: Color(0xFFEA580C),
        lightBg: Color(0xFFFFEDD5),
        icon: CupertinoIcons.phone_fill,
      );
    } else if (clean == 'interested') {
      return const LeadStatusConfig(
        deepColor: Color(0xFF7C3AED),
        lightBg: Color(0xFFEDE9FE),
        icon: CupertinoIcons.star_fill,
      );
    } else if (clean.contains('visit')) {
      return const LeadStatusConfig(
        deepColor: Color(0xFF0D9488),
        lightBg: Color(0xFFCCFBF1),
        icon: CupertinoIcons.map_pin_ellipse,
      );
    } else if (clean.contains('negotiat')) {
      return const LeadStatusConfig(
        deepColor: Color(0xFF4F46E5),
        lightBg: Color(0xFFE0E7FF),
        icon: CupertinoIcons.briefcase_fill,
      );
    } else if (clean == 'qualified') {
      return const LeadStatusConfig(
        deepColor: Color(0xFF2563EB),
        lightBg: Color(0xFFDBEAFE),
        icon: CupertinoIcons.checkmark_seal_fill,
      );
    } else if (clean == 'proposal') {
      return const LeadStatusConfig(
        deepColor: Color(0xFF9333EA),
        lightBg: Color(0xFFF3E8FF),
        icon: CupertinoIcons.doc_text_fill,
      );
    } else if (clean == 'won') {
      return const LeadStatusConfig(
        deepColor: Color(0xFF16A34A),
        lightBg: Color(0xFFDCFCE7),
        icon: CupertinoIcons.checkmark_circle_fill,
      );
    } else if (clean == 'lost' || clean.contains('cancel')) {
      return const LeadStatusConfig(
        deepColor: Color(0xFFDC2626),
        lightBg: Color(0xFFFEE2E2),
        icon: CupertinoIcons.xmark_circle_fill,
      );
    } else if (clean.contains('overdue')) {
      return const LeadStatusConfig(
        deepColor: Color(0xFFDC2626),
        lightBg: Color(0xFFFEE2E2),
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    }

    final hash = status.hashCode.abs();
    final hues = [
      const Color(0xFF0284C7),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFDB2777),
      const Color(0xFF4F46E5),
      const Color(0xFF0D9488),
    ];
    final color = hues[hash % hues.length];
    return LeadStatusConfig(
      deepColor: color,
      lightBg: color.withValues(alpha: 0.12),
      icon: CupertinoIcons.tag_fill,
    );
  }
}

class LeadStatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const LeadStatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final cfg = LeadStatusConfig.fromStatus(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: cfg.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cfg.deepColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            cfg.icon,
            size: small ? 11 : 12.5,
            color: cfg.deepColor,
          ),
          const SizedBox(width: 4.5),
          Text(
            status,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: cfg.deepColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  Color get _c {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'low':
        return AppColors.neutral;
      default:
        return AppColors.brandLight;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: _c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5)),
      child: Text(priority,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _c)));
}

class TaskStatusBadge extends StatelessWidget {
  final String status;

  const TaskStatusBadge({super.key, required this.status});

  Color get _c {
    switch (status) {
      case 'In Progress':
        return AppColors.taskInProgress;
      case 'Review':
        return AppColors.taskReview;
      case 'Completed':
        return AppColors.taskCompleted;
      default:
        return AppColors.taskTodo;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _c)));
}
