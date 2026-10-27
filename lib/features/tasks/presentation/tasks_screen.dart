import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/task_filter_sheet.dart';
import 'widgets/task_item_card.dart';
import 'widgets/task_completion_dialog.dart';
import 'widgets/tasks_skeleton_loader.dart';
import '../data/work_item_store.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../../core/widgets/nec_empty_state.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedScope = 'My Tasks';
  int _selectedTabIndex = 0;

  bool _isSearching = false;
  final _searchController = TextEditingController();

  String? _filterPriority;
  String? _filterRelated;

  final scopeOptions = ['My Tasks', 'Team', 'All'];

  late List<Map<String, dynamic>> _todoTasks;
  late List<Map<String, dynamic>> _inProgressTasks;
  late List<Map<String, dynamic>> _doneTasks;

  @override
  void initState() {
    super.initState();
    _initTasks();
    _selectedScope = DemoSession.instance.isAdmin ? 'All' : 'My Tasks';
    WorkItemStore.instance.addListener(_refreshFromStore);
    _refreshFromStore();
    WorkItemStore.instance.load(preferCache: true).then((_) {
      if (mounted) _refreshFromStore();
    });
  }

  void _refreshFromStore() {
    if (!mounted) return;
    if (WorkItemStore.instance.hasData) {
      final all = WorkItemStore.instance.tasks;
      final todo = <Map<String, dynamic>>[];
      final inProg = <Map<String, dynamic>>[];
      final done = <Map<String, dynamic>>[];

      for (final item in all) {
        if (item.status.toLowerCase() == 'cancelled') continue;
        final initials =
            (item.assigneeName != null && item.assigneeName!.isNotEmpty)
                ? item.assigneeName![0].toUpperCase()
                : 'U';
        final map = {
          'id': item.id,
          'title': item.title,
          'subtitle': '',
          'relatedText': item.leadName,
          'priority': item.priority.toLowerCase() == 'high'
              ? 'High'
              : (item.priority.toLowerCase() == 'low' ? 'Low' : 'Normal'),
          'priorityColor': item.priority.toLowerCase() == 'high'
              ? AppColors.warning
              : (item.priority.toLowerCase() == 'low'
                  ? AppColors.neutral
                  : AppColors.brandLight),
          'assigneeInitials': initials,
          'assigneeName': item.assigneeName ?? 'Unassigned',
          'assigneeId': item.assigneeEmployeeId,
          'relatedType': item.metadata['related_to'] ??
              (item.leadId == null ? 'internal' : 'lead'),
          'leadId': item.leadId,
          'isCompleted': item.isCompleted,
          'status': item.status.toLowerCase(),
          'group': item.isCompleted ? 'COMPLETED' : 'TASKS',
        };
        if (item.isCompleted) {
          done.add(map);
        } else if (item.status.toLowerCase() == 'in_progress') {
          inProg.add(map);
        } else {
          todo.add(map);
        }
      }

      setState(() {
        _todoTasks = todo;
        _inProgressTasks = inProg;
        _doneTasks = done;
      });
    } else {
      setState(_initTasks);
    }
  }

  void _initTasks() {
    _todoTasks = [];
    _inProgressTasks = [];
    _doneTasks = [];
  }

  @override
  void dispose() {
    WorkItemStore.instance.removeListener(_refreshFromStore);
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskFilterSheet(
        selectedPriority: _filterPriority,
        selectedRelated: _filterRelated,
        onApply: (priority, related) {
          setState(() {
            _filterPriority = priority;
            _filterRelated = related;
          });
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(
      List<Map<String, dynamic>> rawList) {
    final query = _searchController.text.trim().toLowerCase();
    return rawList.where((item) {
      if (_selectedScope == 'My Tasks' &&
          item['assigneeId'] != DemoSession.instance.employeeId) {
        return false;
      }
      if (_filterRelated != null &&
          _filterRelated != 'All' &&
          item['relatedType']?.toString().toLowerCase() !=
              _filterRelated!.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty &&
          !item['title'].toString().toLowerCase().contains(query)) {
        return false;
      }
      if (_filterPriority != null && item['priority'] != _filterPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildGroupedSection({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final filtered = _getFilteredList(items);
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: filtered.map((task) {
          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Material(
              color: nec.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: nec.separator.withValues(alpha: 0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: TaskItemCard(
                title: task['title'] as String,
                relatedText: task['relatedText'] as String?,
                subtitle: task['subtitle'] as String,
                priority: task['priority'] as String,
                priorityColor: task['priorityColor'] as Color,
                assigneeInitials: task['assigneeInitials'] as String,
                assigneeName: task['assigneeName'] as String,
                isCompleted: task['isCompleted'] as bool,
                status: task['status'] as String?,
                onStatusChange: (newStatus) async {
                  try {
                    await WorkItemStore.instance.update(
                      task['id'].toString(),
                      {'status': newStatus},
                    );
                    if (!context.mounted) return;
                    NecToast.show(
                      context,
                      message: newStatus == 'in_progress'
                          ? 'Task moved to In Progress'
                          : 'Task moved to To Do',
                      type: NecToastType.success,
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    NecToast.show(context,
                        message: WorkItemStore.messageFor(error),
                        type: NecToastType.error);
                  }
                },
                onToggle: (val) async {
                  if (val == true) {
                    await TaskCompletionDialog.show(
                      context,
                      taskTitle: task['title'] as String,
                      onConfirm: () async {
                        await WorkItemStore.instance.update(
                          task['id'].toString(),
                          {'status': 'completed'},
                        );
                      },
                    );
                  } else {
                    try {
                      await WorkItemStore.instance.update(
                        task['id'].toString(),
                        {'status': 'to_do'},
                      );
                      if (!context.mounted) return;
                      NecToast.show(context,
                          message: 'Task moved back to To Do',
                          type: NecToastType.info);
                    } catch (error) {
                      if (!context.mounted) return;
                      NecToast.show(context,
                          message: WorkItemStore.messageFor(error),
                          type: NecToastType.error);
                    }
                  }
                },
                onTap: () => context.push('/tasks/${task['id']}'),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final todoCount = _getFilteredList(_todoTasks).length;
    final visibleTasks = _getFilteredList(_selectedTabIndex == 0
        ? _todoTasks
        : _selectedTabIndex == 1
            ? _inProgressTasks
            : _doneTasks);
    final initialLoading = !WorkItemStore.instance.hasData &&
        WorkItemStore.instance.loadError == null;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isSearching
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: nec.surface,
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
                                autofocus: true,
                                onChanged: (v) => setState(() {}),
                                style: TextStyle(
                                    color: nec.textPrimary, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  hintStyle: TextStyle(
                                    color: nec.textTertiary,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: nec.brand,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openFilterSheet,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: nec.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.slider_horizontal_3,
                              color: nec.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: nec.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.search,
                              color: nec.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap:
                              StaffAccessStore.instance.canOpen('/create-task')
                                  ? () => context.push('/create-task')
                                  : null,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5856D6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!_isSearching) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: scopeOptions.map((scope) {
                    final isSelected = _selectedScope == scope;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedScope = scope;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5856D6)
                              : nec.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          scope,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isSelected ? Colors.white : nec.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: nec.separator.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFF5856D6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'To Do',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedTabIndex == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _selectedTabIndex == 0
                                      ? nec.textPrimary
                                      : nec.textTertiary,
                                ),
                              ),
                              if (todoCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$todoCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFF5856D6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'In Progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedTabIndex == 1
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedTabIndex == 1
                                    ? nec.textPrimary
                                    : nec.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == 2
                                    ? const Color(0xFF5856D6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedTabIndex == 2
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedTabIndex == 2
                                    ? nec.textPrimary
                                    : nec.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5856D6),
                backgroundColor: nec.surface,
                onRefresh: () async {
                  await WorkItemStore.instance.load(force: true);
                  _refreshFromStore();
                },
                child: visibleTasks.isEmpty && !initialLoading
                    ? CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: NecEmptyState(
                              icon: CupertinoIcons.checkmark_seal_fill,
                              color: const Color(0xFF5856D6),
                              title: WorkItemStore.instance.loadError != null
                                  ? 'Tasks are unavailable'
                                  : 'No tasks found',
                              message: WorkItemStore.instance.loadError ??
                                  'There are no tasks in this view. Adjust your filters or pull down to refresh.',
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (initialLoading) ...[
                              const TasksSkeletonLoader(itemCount: 5),
                            ] else if (_selectedTabIndex == 0) ...[
                              _buildGroupedSection(
                                context: context,
                                title: 'TO DO',
                                items: _todoTasks,
                              ),
                            ] else if (_selectedTabIndex == 1) ...[
                              _buildGroupedSection(
                                context: context,
                                title: 'IN PROGRESS',
                                items: _inProgressTasks,
                              ),
                            ] else ...[
                              _buildGroupedSection(
                                  context: context,
                                  title: 'COMPLETED',
                                  items: _doneTasks),
                            ],
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
