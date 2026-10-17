import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../tasks/data/work_item_store.dart';

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({super.key, required this.issueId});

  final String issueId;

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final _resolution = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WorkItemStore.instance.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WorkItemStore.instance
          .fetchDetails(widget.issueId, type: 'issue', force: true);
    } catch (error) {
      if (mounted) _error = WorkItemStore.messageFor(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    WorkItemStore.instance.removeListener(_refresh);
    _resolution.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (!DemoSession.instance.isAdmin || _saving) return;
    final notes = _resolution.text.trim();
    if (notes.isEmpty) {
      NecToast.show(context,
          message: 'Please describe the resolution.', type: NecToastType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await WorkItemStore.instance
          .update(widget.issueId, {'status': 'completed', 'result': notes});
      if (!mounted) return;
      NecToast.show(context,
          message: 'Issue resolved', type: NecToastType.success);
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final item = WorkItemStore.instance.byId(widget.issueId);
    final resolved = item?.isCompleted == true ||
        ['resolved', 'closed'].contains(item?.status);
    Widget card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: nec.surface, borderRadius: BorderRadius.circular(16)),
        child: child);
    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
          backgroundColor: nec.bg,
          title: const Text('Issue'),
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : item == null
                  ? const Center(child: Text('Issue unavailable'))
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      card(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: nec.textPrimary)),
                            const SizedBox(height: 12),
                            Text(
                                'Status: ${resolved ? 'Resolved' : item.status.replaceAll('_', ' ')}'),
                            const SizedBox(height: 8),
                            Text('Priority: ${item.priority}'),
                            if (item.metadata['category'] != null) ...[
                              const SizedBox(height: 8),
                              Text('Category: ${item.metadata['category']}')
                            ],
                            const SizedBox(height: 12),
                            Text(item.details ??
                                item.metadata['description']?.toString() ??
                                ''),
                          ])),
                      if (item.leadName != null) ...[
                        const SizedBox(height: 12),
                        card(Text('Related lead: ${item.leadName}'))
                      ],
                      if (resolved && item.result?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        card(Text(item.result!))
                      ],
                      if (DemoSession.instance.isAdmin && !resolved) ...[
                        const SizedBox(height: 16),
                        card(TextField(
                            controller: _resolution,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                                labelText: 'Resolution notes',
                                border: InputBorder.none))),
                        const SizedBox(height: 16),
                        NecButton(
                            label: 'Resolve Issue',
                            onPressed: _saving ? null : _resolve,
                            fullWidth: true),
                      ],
                    ]),
    );
  }
}
