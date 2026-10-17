import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/role_store.dart';

class PermissionCatalogScreen extends StatefulWidget {
  const PermissionCatalogScreen({super.key});

  @override
  State<PermissionCatalogScreen> createState() =>
      _PermissionCatalogScreenState();
}

class _PermissionCatalogScreenState extends State<PermissionCatalogScreen> {
  final _store = RoleStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await _store.loadCatalog();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Scaffold(
        backgroundColor: nec.bg,
        appBar: AppBar(
            title: const Text('Permission Catalog'), backgroundColor: nec.bg),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_loading && _store.catalog.isEmpty)
                    const CupertinoActivityIndicator(),
                  if (_store.catalogError != null)
                    ListTile(
                        title: Text(_store.catalogError!),
                        trailing: TextButton(
                            onPressed: _load, child: const Text('Retry'))),
                  for (final module in _store.catalog)
                    Card(
                        color: nec.surface,
                        child: ExpansionTile(
                            title: Text('${module['label'] ?? module['key']}'),
                            children: [
                              for (final permission
                                  in module['permissions'] as List)
                                ListTile(
                                    title: Text('${permission['label']}'),
                                    subtitle: Text('${permission['key']}'))
                            ])),
                ])));
  }
}
