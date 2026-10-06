import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/task_filter_sheet.dart';
import 'widgets/task_item_card.dart';

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
  }

  void _initTasks() {
    _todoTasks = [
      {
        'id': 'task_1',
        'title': 'Prepare hotel onboarding checklist',
        'subtitle': 'Operations · Tomorrow',
        'priority': 'Normal',
        'priorityColor': AppColors.brandLight,
        'assigneeInitials': 'A',
        'assigneeName': 'Akter',
        'isCompleted': false,
        'group': 'TOMORROW',
      },
      {
        'id': 'task_2',
        'title': 'Review sales target for Q4',
        'subtitle': 'Sales · Next Week',
        'priority': 'Low',
        'priorityColor': AppColors.neutral,
        'assigneeInitials': 'A',
        'assigneeName': 'Akter',
        'isCompleted': false,
        'group': 'NEXT WEEK',
      },
    ];

    _inProgressTasks = [
      {
        'id': 'task_3',
        'title': 'Send proposal draft to Sea Pearl Resort',
        'relatedText': 'Sea Pearl Resort',
        'subtitle': 'Today · 5:00 PM',
        'priority': 'High',
        'priorityColor': AppColors.warning,
        'assigneeInitials': 'A',
        'assigneeName': 'Akter',
        'isCompleted': false,
        'group': 'TODAY',
      },
    ];

    _doneTasks = [
      {
        'id': 'task_4',
        'title': 'Prepare Blue Wave Resort demo',
        'relatedText': 'Blue Wave Resort',
        'subtitle': 'Today · 2:00 PM',
        'priority': 'High',
        'priorityColor': AppColors.warning,
        'assigneeInitials': 'A',
        'assigneeName': 'Akter',
        'isCompleted': true,
        'group': 'COMPLETED TODAY',
      },
      {
        'id': 'task_5',
        'title': 'Prepare monthly report deck',
        'subtitle': 'Management · Sep 25, 2026',
        'priority': 'Normal',
        'priorityColor': AppColors.brandLight,
        'assigneeInitials': 'A',
        'assigneeName': 'Akter',
        'isCompleted': true,
        'group': 'EARLIER',
      },
    ];
  }

  @override
  void dispose() {
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: nec.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(filtered.length, (index) {
                final task = filtered[index];
                final isLast = index == filtered.length - 1;

                return Column(
                  children: [
                    TaskItemCard(
                      title: task['title'] as String,
                      relatedText: task['relatedText'] as String?,
                      subtitle: task['subtitle'] as String,
                      priority: task['priority'] as String,
                      priorityColor: task['priorityColor'] as Color,
                      assigneeInitials: task['assigneeInitials'] as String,
                      assigneeName: task['assigneeName'] as String,
                      isCompleted: task['isCompleted'] as bool,
                      onToggle: (val) {
                        setState(() {
                          task['isCompleted'] = val ?? false;
                        });
                      },
                      onTap: () => context.push('/tasks/${task['id']}'),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.3),
                        indent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final todoCount = _getFilteredList(_todoTasks).length;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_selectedTabIndex == 0) ...[
                      _buildGroupedSection(
                        context: context,
                        title: 'TOMORROW',
                        items: _todoTasks,
                      ),
                    ] else if (_selectedTabIndex == 1) ...[
                      _buildGroupedSection(
                        context: context,
                        title: 'TODAY',
                        items: _inProgressTasks,
                      ),
                    ] else ...[
                      _buildGroupedSection(
                        context: context,
                        title: 'COMPLETED TODAY',
                        items: _doneTasks
                            .where((x) => x['group'] == 'COMPLETED TODAY')
                            .toList(),
                      ),
                      _buildGroupedSection(
                        context: context,
                        title: 'EARLIER',
                        items: _doneTasks
                            .where((x) => x['group'] == 'EARLIER')
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
