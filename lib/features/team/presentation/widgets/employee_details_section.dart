import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeDetailsSection extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  final Map<String, VoidCallback>? onRowTap;

  const EmployeeDetailsSection({
    super.key,
    required this.title,
    required this.rows,
    this.onRowTap,
  });

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
              Builder(builder: (context) {
                final rowLabel = rows[index].$1;
                final isTapAction =
                    onRowTap != null && onRowTap!.containsKey(rowLabel);

                final content = Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(rowLabel,
                                  style: TextStyle(
                                      color: nec.textSecondary, fontSize: 13))),
                          const SizedBox(width: 12),
                          Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Builder(
                                      builder: (context) {
                                        final text = rows[index].$2.trim();
                                        final isMissing = text.isEmpty ||
                                            text.toLowerCase() == 'null' ||
                                            text.toLowerCase() == 'undefined';
                                        return Text(
                                          isMissing ? 'Not provided' : text,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                              color: isMissing
                                                  ? nec.textTertiary
                                                  : nec.textPrimary,
                                              fontSize: 14,
                                              fontWeight: isTapAction
                                                  ? FontWeight.w600
                                                  : FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                  if (isTapAction) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      CupertinoIcons.pencil_circle_fill,
                                      size: 16,
                                      color: AppColors.brandLight,
                                    ),
                                  ],
                                ],
                              )),
                        ]));

                if (isTapAction) {
                  return InkWell(
                    onTap: onRowTap![rowLabel],
                    child: content,
                  );
                }
                return content;
              }),
            ],
          ])),
    ]);
  }
}
