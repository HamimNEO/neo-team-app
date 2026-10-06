import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../../leads/domain/models/lead.dart';

class TodayLeadsList extends StatelessWidget {
  final List<Lead> leads;

  const TodayLeadsList({super.key, required this.leads});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: leads
            .map(
              (lead) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.brandLight,
                    size: 18,
                  ),
                ),
                title: Text(
                  lead.company,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: nec.textPrimary,
                  ),
                ),
                subtitle: Text(
                  lead.nextActionNote ?? 'Follow-up',
                  style: TextStyle(fontSize: 12, color: nec.textTertiary),
                ),
                trailing: LeadStatusBadge(status: lead.status, small: true),
                onTap: () => context.push('/leads/${lead.id}'),
              ),
            )
            .toList(),
      ),
    );
  }
}
