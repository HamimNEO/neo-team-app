import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/audit_store.dart';
import '../../../core/widgets/nec_toast.dart';
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
  final _store = AuditStore.instance;
  DateTimeRange? _range;
  String? _actorId, _eventType;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _store.load(force: true);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    try {
      await _store.export(
          actorId: _actorId,
          eventType: _eventType,
          from: _range?.start.toIso8601String().split('T').first,
          to: _range?.end.toIso8601String().split('T').first);
    } catch (e) {
      if (mounted) {
        NecToast.show(context,
            message: e is FormatException ? e.message : 'Export failed.',
            type: NecToastType.error);
      }
    }
  }

  Future<void> _serverFilter() async {
    final actor = TextEditingController(text: _actorId ?? ''),
        event = TextEditingController(text: _eventType ?? '');
    final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Audit filters'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: actor,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Actor user ID (optional)')),
                  TextField(
                      controller: event,
                      decoration: const InputDecoration(
                          labelText: 'Event type (optional)'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Apply'))
                ]));
    if (ok == true && mounted) {
      _actorId = actor.text.trim();
      _eventType = event.text.trim();
      await _loadFiltered();
    }
    actor.dispose();
    event.dispose();
  }

  Future<void> _loadFiltered() => _store.load(force: true, filters: {
        if (_actorId?.isNotEmpty == true) 'actor_id': _actorId!,
        if (_eventType?.isNotEmpty == true) 'event_type': _eventType!,
        if (_range != null)
          'from_date': _range!.start.toIso8601String().split('T').first,
        if (_range != null)
          'to_date': _range!.end.toIso8601String().split('T').first
      });

  @override
  void dispose() {
    _store.removeListener(_refresh);
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
    setState(() {
      _selectedCategory = null;
      _actorId = null;
      _eventType = null;
      _range = null;
    });
    _loadFiltered();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final entries = _store.entries
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
          if (_store.loading) const LinearProgressIndicator(minHeight: 2),
          if (_store.error != null) ...[
            Text(_store.error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _loadFiltered, child: const Text('Retry'))
          ],
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: _store.loading ? null : _loadFiltered,
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Refresh')),
            TextButton.icon(
                onPressed: _serverFilter,
                icon: const Icon(CupertinoIcons.slider_horizontal_3),
                label: const Text('Actor / event')),
            TextButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _range);
                  if (range != null && mounted) {
                    setState(() => _range = range);
                    await _loadFiltered();
                  }
                },
                icon: const Icon(CupertinoIcons.calendar),
                label: const Text('Date range')),
            TextButton.icon(
                onPressed: _export,
                icon: const Icon(CupertinoIcons.arrow_down_doc),
                label: const Text('Export'))
          ]),
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
