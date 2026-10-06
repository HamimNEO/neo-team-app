import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audit_entry.dart';
import 'audit_high_badge.dart';
import 'audit_style.dart';

class AuditSummaryCard extends StatelessWidget {
  final AuditEntry entry;

  const AuditSummaryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final categoryColor = auditCategoryColor(entry.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: categoryColor, shape: BoxShape.circle),
              ),
              Text(
                entry.category.label.toUpperCase(),
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 12,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entry.highImpact) const AuditHighBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.action,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(entry.entity,
              style: TextStyle(fontSize: 15, color: nec.textSecondary)),
        ],
      ),
    );
  }
}

class AuditMetadataCard extends StatelessWidget {
  final AuditEntry entry;

  const AuditMetadataCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final rows = [
      ('Changed by', entry.actor),
      ('Entity', '${entry.entity} (${entry.entityType})'),
      ('Timestamp', auditTimestampLabel(entry.timestamp)),
      ('Category', entry.category.label),
    ];

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[index].$1,
                      style: TextStyle(fontSize: 14, color: nec.textTertiary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[index].$2,
                      textAlign: TextAlign.right,
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
            if (index < rows.length - 1)
              Divider(height: 1, thickness: 0.5, color: nec.separator),
          ],
        ],
      ),
    );
  }
}

class AuditChangesCard extends StatelessWidget {
  final List<AuditChange> changes;

  const AuditChangesCard({super.key, required this.changes});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < changes.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    changes[index].field,
                    style: TextStyle(fontSize: 13, color: nec.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ChangeValue(
                          value: changes[index].before, color: AppColors.error),
                      Icon(CupertinoIcons.arrow_right,
                          size: 14, color: nec.textTertiary),
                      _ChangeValue(
                          value: changes[index].after,
                          color: AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
            if (index < changes.length - 1)
              Divider(height: 1, thickness: 0.5, color: nec.separator),
          ],
        ],
      ),
    );
  }
}

class _ChangeValue extends StatelessWidget {
  final String value;
  final Color color;

  const _ChangeValue({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(value,
            style: TextStyle(fontSize: 13, height: 1.2, color: color)),
      );
}
