import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_audit_entries.dart';
import 'widgets/audit_app_bar.dart';
import 'widgets/audit_detail_cards.dart';

class AuditDetailScreen extends StatelessWidget {
  final String auditId;

  const AuditDetailScreen({super.key, required this.auditId});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final entry = findAuditEntry(auditId);

    return Scaffold(
      backgroundColor: nec.bg,
      appBar:
          const AuditAppBar(title: 'Audit Detail', fallbackPath: '/audit-logs'),
      body: entry == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Audit record not found',
                    style: TextStyle(fontSize: 17, color: nec.textPrimary),
                  ),
                  CupertinoButton(
                    onPressed: () => context.go('/audit-logs'),
                    child: Text('View audit logs',
                        style: TextStyle(color: nec.brand)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                AuditSummaryCard(entry: entry),
                const SizedBox(height: 16),
                AuditMetadataCard(entry: entry),
                const SizedBox(height: 20),
                Text(
                  'CHANGES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                if (entry.changes.isNotEmpty)
                  AuditChangesCard(changes: entry.changes)
                else
                  Text(
                    'No field-level changes were recorded for this event.',
                    style: TextStyle(fontSize: 14, color: nec.textSecondary),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color.lerp(nec.bg, nec.surface, 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Audit records are read-only. They cannot be edited, '
                    'deleted, or backdated.',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: nec.textTertiary),
                  ),
                ),
              ],
            ),
    );
  }
}
