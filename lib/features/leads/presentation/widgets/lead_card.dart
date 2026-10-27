import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../domain/models/lead.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/lead_store.dart';

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
    final employee = EmployeeStore.instance.byId(lead.assignedEmployeeId ?? '');
    final assignee = LeadStore.instance.assigneeName(lead);
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
                [
                  if (lead.contactName != null &&
                      lead.contactName!.trim().isNotEmpty)
                    lead.contactName!.trim(),
                  if (lead.location.isNotEmpty) lead.location,
                  if (lead.type.isNotEmpty) lead.type,
                  if (lead.phone != null && lead.phone!.trim().isNotEmpty)
                    lead.phone!.trim(),
                ].join(' · '),
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
                    initials: employee?.avatarInitials ??
                        Employee.initialsFor(assignee),
                    photoBase64: employee?.photoBase64,
                    photoUrl: employee?.photoUrl,
                    assetPath: employee?.avatarAsset,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    assignee,
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
