import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/department_store.dart';
import '../../data/employee_store.dart';
import '../../domain/models/employee.dart';

class AddDepartmentMemberSheet extends StatefulWidget {
  const AddDepartmentMemberSheet({
    super.key,
    required this.departmentId,
    required this.departmentName,
    this.onMemberAdded,
  });

  final String departmentId;
  final String departmentName;
  final ValueChanged<String>? onMemberAdded;

  @override
  State<AddDepartmentMemberSheet> createState() =>
      _AddDepartmentMemberSheetState();
}

class _AddDepartmentMemberSheetState extends State<AddDepartmentMemberSheet> {
  final _store = EmployeeStore.instance;
  final _searchController = TextEditingController();
  bool _saving = false;
  String? _error;

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

  Future<void> _add(Employee employee) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await DepartmentStore.instance
          .assignMembers(widget.departmentId, [int.parse(employee.backendId!)]);
      await _store.load();
      if (!mounted) return;
      NecToast.show(
        context,
        message: 'Added ${employee.name} to ${widget.departmentName}',
        type: NecToastType.success,
      );
      widget.onMemberAdded?.call(employee.id);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = EmployeeStore.messageFor(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final query = _searchController.text.trim().toLowerCase();

    final candidates = _store.employees.where((e) {
      if (e.status != 'Active' || e.backendId == null) return false;
      if (e.departmentId == widget.departmentId) return false;
      if (query.isNotEmpty) {
        return e.name.toLowerCase().contains(query) ||
            e.designation.toLowerCase().contains(query) ||
            e.department.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return PopScope(
      canPop: !_saving,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add Member to ${widget.departmentName}',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: nec.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 16,
                          color: nec.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search employee...',
                              hintStyle: TextStyle(
                                fontSize: 14.5,
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
                              size: 16,
                              color: nec.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                Expanded(
                  child: candidates.isEmpty
                      ? Center(
                          child: Text(
                            query.isEmpty
                                ? 'No other active employees to add'
                                : 'No matching employees found',
                            style: TextStyle(
                              color: nec.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: candidates.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 52,
                            color: nec.separator.withValues(alpha: 0.3),
                          ),
                          itemBuilder: (context, index) {
                            final emp = candidates[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              leading: NecAvatar(
                                initials: emp.avatarInitials,
                                photoUrl: emp.photoUrl,
                                photoBase64: emp.photoBase64,
                                size: 40,
                              ),
                              title: Text(
                                emp.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${emp.designation}${emp.department.isNotEmpty ? ' · Current: ${emp.department}' : ''}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: nec.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                color: AppColors.brandLight
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                onPressed: _saving ? null : () => _add(emp),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppColors.brandLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
