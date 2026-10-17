import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/role_store.dart';
import '../domain/models/system_role.dart';

class RolePermissionsScreen extends StatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  State<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  final _searchController = TextEditingController();
  final _store = RoleStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _store.load();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _openNewRoleScreen() async {
    await context.push<SystemRoleItem>('/new-role');
    if (mounted) _store.load();
  }

  List<SystemRoleItem> _getFilteredRoles(List<SystemRoleItem> liveRoles) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return liveRoles;
    return liveRoles.where((r) {
      return r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.badge.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final liveRoles = _store.roles;
    final filtered = _getFilteredRoles(liveRoles);
    final systemRoles = filtered.where((r) => r.badge == 'SYSTEM').toList();
    final customRoles = filtered.where((r) => r.badge == 'CUSTOM').toList();

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.pop();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Roles & Permissions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _openNewRoleScreen,
                child: Text(
                  '+ New',
                  style: TextStyle(
                    color: nec.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                      leading: Icon(CupertinoIcons.person_2, color: nec.brand),
                      title: const Text('Staff Access'),
                      subtitle:
                          const Text('Employee module availability settings'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.push('/staff-access'))),
              const SizedBox(height: 20),
              Material(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                      leading:
                          Icon(CupertinoIcons.list_bullet, color: nec.brand),
                      title: const Text('Permission Catalog'),
                      subtitle:
                          const Text('Available server permissions by module'),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: () => context.push('/permission-catalog'))),
              const SizedBox(height: 12),
              if (_store.loading && liveRoles.isEmpty)
                const Center(child: CupertinoActivityIndicator()),
              if (_store.error != null || _store.catalogError != null)
                ListTile(
                  title: Text(_store.error ?? _store.catalogError!),
                  trailing: TextButton(
                      onPressed: _store.load, child: const Text('Retry')),
                ),
              if (!_store.loading && liveRoles.isEmpty && _store.error == null)
                const Center(child: Text('No roles available')),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? nec.surface
                      : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 18,
                      color: nec.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search roles',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: nec.textTertiary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(
                          CupertinoIcons.clear_thick_circled,
                          size: 18,
                          color: nec.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (systemRoles.isNotEmpty) ...[
                Text(
                  'SYSTEM ROLES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildRoleGroupCard(nec, systemRoles),
                const SizedBox(height: 24),
              ],
              if (customRoles.isNotEmpty) ...[
                Text(
                  'CUSTOM ROLES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: nec.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildRoleGroupCard(nec, customRoles),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleGroupCard(NecColors nec, List<SystemRoleItem> roles) {
    return Material(
      color: nec.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(roles.length, (index) {
          final role = roles[index];
          final isLast = index == roles.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: role.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.shield,
                    color: role.iconColor,
                    size: 18,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: nec.separator.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role.badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: role.badge == 'CUSTOM'
                              ? AppColors.warning
                              : nec.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: nec.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${role.memberCount} ${role.memberCount == 1 ? 'member' : 'members'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: nec.textTertiary,
                ),
                onTap: () => context.push('/role-details/${role.id}'),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: nec.separator.withValues(alpha: 0.2),
                  indent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}
