import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeDetailsSection extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const EmployeeDetailsSection(
      {super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: nec.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5))),
      Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: nec.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                Divider(height: 1, indent: 16, color: nec.separator),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(rows[index].$1,
                                style: TextStyle(
                                    color: nec.textSecondary, fontSize: 13))),
                        const SizedBox(width: 16),
                        Expanded(
                            flex: 3,
                            child: Text(
                                rows[index].$2.trim().isEmpty
                                    ? 'Not provided'
                                    : rows[index].$2,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: nec.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                      ])),
            ],
          ])),
    ]);
  }
}
