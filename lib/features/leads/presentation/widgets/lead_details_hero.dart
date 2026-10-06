import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../domain/models/lead.dart';

class LeadDetailsHero extends StatelessWidget {
  final Lead lead;

  const LeadDetailsHero({super.key, required this.lead});

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final statusColor = AppColors.leadStatusColor(lead.status);

    return Container(
      color: nec.bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  lead.company.isNotEmpty ? lead.company[0] : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.company,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    Text(
                      '${lead.location} · ${lead.type}',
                      style: TextStyle(
                        fontSize: 14,
                        color: nec.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              LeadStatusBadge(status: lead.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPill(lead.priority, AppColors.warning),
              if (lead.source != null) ...[
                const SizedBox(width: 8),
                _buildPill(lead.source!, AppColors.brandLight),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
