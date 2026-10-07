import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ManagementSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<(String, String, Color)> metrics;
  final double progress;
  final String progressLabel;
  final VoidCallback onTap;

  const ManagementSummaryCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.accent,
      required this.metrics,
      required this.progress,
      required this.progressLabel,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final radius = BorderRadius.circular(22);
    return Material(
      color: nec.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
          decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.16)),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withValues(alpha: 0.07), nec.surface])),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(icon, size: 23, color: accent)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: TextStyle(
                                      color: nec.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(subtitle,
                                  style: TextStyle(
                                      color: nec.textSecondary, fontSize: 12)),
                            ])),
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_right,
                            color: accent, size: 16),
                      ]),
                      const SizedBox(height: 22),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < metrics.length;
                                index++) ...[
                              if (index > 0) ...[
                                const SizedBox(width: 16),
                                Container(
                                    width: 1,
                                    height: 46,
                                    color:
                                        nec.separator.withValues(alpha: 0.5)),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(metrics[index].$2,
                                            style: TextStyle(
                                                color: metrics[index].$3,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700))),
                                    const SizedBox(height: 5),
                                    Text(metrics[index].$1,
                                        style: TextStyle(
                                            color: nec.textSecondary,
                                            fontSize: 12,
                                            height: 1.3)),
                                  ])),
                            ],
                          ]),
                      const SizedBox(height: 20),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0).toDouble(),
                              minHeight: 5,
                              color: accent,
                              backgroundColor: accent.withValues(alpha: 0.12))),
                      const SizedBox(height: 9),
                      Text(progressLabel,
                          style: TextStyle(
                              color: nec.textSecondary,
                              fontSize: 11,
                              height: 1.4)),
                    ])),
          )),
    );
  }
}
