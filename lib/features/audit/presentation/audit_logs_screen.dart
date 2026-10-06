import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mock_audit_entries.dart';
import '../domain/models/audit_entry.dart';
import 'widgets/audit_app_bar.dart';
import 'widgets/audit_category_chips.dart';
import 'widgets/audit_category_filter_sheet.dart';
import 'widgets/audit_log_row.dart';
import 'widgets/audit_style.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchController = TextEditingController();
  AuditCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(AuditCategory? category) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedCategory = category);
  }

  void _openFilter() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditCategoryFilterSheet(
        selectedCategory: _selectedCategory,
        onSelected: _selectCategory,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _selectedCategory = null);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final entries = mockAuditEntries
        .where((entry) =>
            (_selectedCategory == null ||
                entry.category == _selectedCategory) &&
            entry.matchesSearch(_searchController.text))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final grouped = <DateTime, List<AuditEntry>>{};
    for (final entry in entries) {
      final date = DateUtils.dateOnly(entry.timestamp);
      grouped.putIfAbsent(date, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AuditAppBar(
        title: 'Audit Logs',
        fallbackPath: '/administration',
        onFilter: _openFilter,
        filtered: _selectedCategory != null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 40,
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search actor, entity, action',
                placeholderStyle:
                    TextStyle(fontSize: 15, color: nec.textTertiary),
                style: TextStyle(fontSize: 15, color: nec.textPrimary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.search,
                      size: 17, color: nec.textTertiary),
                ),
                suffix: _searchController.text.isEmpty
                    ? null
                    : CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 17,
                          color: nec.textTertiary,
                          semanticLabel: 'Clear search',
                        ),
                      ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color.lerp(nec.bg, nec.surface, 0.3)
                      : nec.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ),
          AuditCategoryChips(
            selectedCategory: _selectedCategory,
            onSelected: _selectCategory,
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.search,
                              size: 40, color: nec.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'No audit logs found',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try another search or category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: nec.textSecondary),
                          ),
                          CupertinoButton(
                            onPressed: _clearFilters,
                            child: Text('Clear filters',
                                style: TextStyle(color: nec.brand)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      for (final group in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            auditDayLabel(group.key).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w600,
                              color: nec.textTertiary,
                            ),
                          ),
                        ),
                        Material(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < group.value.length;
                                  index++) ...[
                                AuditLogRow(
                                  entry: group.value[index],
                                  onTap: () => context.push(
                                      '/audit-logs/${group.value[index].id}'),
                                ),
                                if (index < group.value.length - 1)
                                  Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: nec.separator),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
