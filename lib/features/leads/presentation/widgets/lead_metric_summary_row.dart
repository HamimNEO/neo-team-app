import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LeadMetricSummaryRow extends StatelessWidget {
  final int newCount;
  final int followUpCount;
  final int visitsTodayCount;
  final int negotiationCount;
  final ValueChanged<String>? onMetricTap;

  const LeadMetricSummaryRow({
    super.key,
    this.newCount = 0,
    this.followUpCount = 0,
    this.visitsTodayCount = 0,
    this.negotiationCount = 0,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final metrics = [
      {'count': newCount, 'label': 'New'},
      {'count': followUpCount, 'label': 'Follow-up'},
      {'count': visitsTodayCount, 'label': 'Visits Today'},
      {'count': negotiationCount, 'label': 'Negotiation'},
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
          final count = item['count'] as int;
          final label = item['label'] as String;

          final card = Container(
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
                _AnimatedCounterText(
                  count: count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
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

          if (onMetricTap != null) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onMetricTap!(label),
              child: card,
            );
          }
          return card;
        },
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  final int count;
  final TextStyle style;

  const _AnimatedCounterText({
    required this.count,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '${val.round()}',
          style: style,
        );
      },
    );
  }
}
