import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../domain/models/lead.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final bool showDivider;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: lead.isOverdue
          ? AppColors.error.withValues(alpha: 0.025)
          : nec.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.company,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                  ),
                  LeadStatusBadge(status: lead.status, small: true),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${lead.location} · ${lead.type}',
                style: TextStyle(fontSize: 12, color: nec.textTertiary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    lead.isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.schedule,
                    size: 13,
                    color: lead.isOverdue ? AppColors.error : nec.brand,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lead.nextActionNote ?? 'No action',
                    style: TextStyle(
                      fontSize: 13,
                      color: lead.isOverdue ? AppColors.error : nec.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (lead.isOverdue) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '· Overdue',
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  NecAvatar(
                    initials: lead.assignedTo?.substring(0, 2) ?? '??',
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lead.assignedTo ?? 'Unassigned',
                    style: TextStyle(fontSize: 12, color: nec.textTertiary),
                  ),
                ],
              ),
              if (showDivider) ...[
                const SizedBox(height: 12),
                Divider(height: 0.5, color: nec.separator),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
