import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LeadInfoRow {
  final String label;
  final String value;

  const LeadInfoRow(this.label, this.value);
}

class LeadInfoGroup extends StatelessWidget {
  final String title;
  final List<LeadInfoRow> rows;

  const LeadInfoGroup({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: nec.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              final row = entry.value;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            row.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: nec.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      indent: 16,
                      endIndent: 0,
                      height: 0.5,
                      color: nec.separator,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
