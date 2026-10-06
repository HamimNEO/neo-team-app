import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LeadMetricSummaryRow extends StatelessWidget {
  final int newCount;
  final int followUpCount;
  final int visitsTodayCount;
  final int negotiationCount;

  const LeadMetricSummaryRow({
    super.key,
    this.newCount = 3,
    this.followUpCount = 3,
    this.visitsTodayCount = 2,
    this.negotiationCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final metrics = [
      {'value': '$newCount', 'label': 'New'},
      {'value': '$followUpCount', 'label': 'Follow-up'},
      {'value': '$visitsTodayCount', 'label': 'Visits Today'},
      {'value': '$negotiationCount', 'label': 'Negotiation'},
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = metrics[index];
          return Container(
            width: 104,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: nec.separator.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['value']!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: nec.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
