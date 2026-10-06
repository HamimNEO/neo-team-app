import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_button.dart';

class LeadFilterSortSheet extends StatefulWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const LeadFilterSortSheet({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  State<LeadFilterSortSheet> createState() => _LeadFilterSortSheetState();
}

class _LeadFilterSortSheetState extends State<LeadFilterSortSheet> {
  late String _currentSort;
  String _activeView = 'main';

  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedEmployees = {};
  final Set<String> _selectedSources = {};
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedPriorities = {};

  final _employeeSearchController = TextEditingController();

  final sortOptions = [
    'Recently Updated',
    'Newest',
    'Oldest',
    'Next Action',
    'Priority',
  ];

  final statusOptions = [
    {'label': 'New', 'color': AppColors.brandLight},
    {'label': 'Contacted', 'color': AppColors.leadContacted},
    {'label': 'Interested', 'color': AppColors.leadInterested},
    {'label': 'Follow-up', 'color': AppColors.warning},
    {'label': 'Visit Scheduled', 'color': AppColors.leadVisit},
    {'label': 'Negotiation', 'color': AppColors.leadNegotiation},
    {'label': 'Won', 'color': AppColors.success},
    {'label': 'Lost', 'color': AppColors.error},
  ];

  final employeeOptions = [
    {
      'name': 'Unassigned',
      'designation': '',
      'initials': '??',
      'color': Colors.transparent,
      'count': ''
    },
    {
      'name': 'Me (Shahina Akter)',
      'designation': '',
      'initials': 'SA',
      'color': AppColors.brandLight,
      'count': ''
    },
    {
      'name': 'Rahul Mehta',
      'designation': 'Sales Manager',
      'initials': 'RM',
      'color': AppColors.success,
      'count': '21 leads'
    },
    {
      'name': 'Priya Das',
      'designation': 'Sales Executive',
      'initials': 'PD',
      'color': AppColors.warning,
      'count': '18 leads'
    },
    {
      'name': 'Fahim Ahmed',
      'designation': 'Field Sales',
      'initials': 'FA',
      'color': AppColors.leadInterested,
      'count': '12 leads'
    },
    {
      'name': 'Tania Rahman',
      'designation': 'Sales Executive',
      'initials': 'TR',
      'color': AppColors.leadNegotiation,
      'count': '9 leads'
    },
    {
      'name': 'Karim Hossain',
      'designation': 'Sales Executive',
      'initials': 'KH',
      'color': AppColors.error,
      'count': '7 leads'
    },
  ];

  final sourceOptions = [
    'Facebook',
    'Website',
    'WhatsApp',
    'Phone',
    'Referral',
    'Field Visit',
    'Campaign',
    'Manual',
    'Custom',
  ];

  final typeOptions = [
    'Hotel',
    'Resort',
    'Guest House',
    'Restaurant',
    'Company',
    'Agency',
  ];

  final priorityOptions = [
    {'label': 'Low', 'color': AppColors.neutral},
    {'label': 'Normal', 'color': AppColors.brandLight},
    {'label': 'High', 'color': AppColors.warning},
    {'label': 'Urgent', 'color': AppColors.error},
  ];

  @override
  void initState() {
    super.initState();
    _currentSort = widget.selectedSort;
  }

  @override
  void dispose() {
    _employeeSearchController.dispose();
    super.dispose();
  }

  void _toggleSelection(Set<String> set, String item) {
    setState(() {
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
      }
    });
  }

  Widget _buildCheckbox(bool isChecked) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? nec.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color:
              isChecked ? nec.brand : nec.textTertiary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: isChecked
          ? const Icon(
              CupertinoIcons.checkmark_alt,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildSubHeader(String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _activeView = 'main';
                  });
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
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildMainView(NecColors nec) {
    final filterCategories = [
      {'key': 'status', 'label': 'Status'},
      {'key': 'assigned', 'label': 'Assigned Employee'},
      {'key': 'source', 'label': 'Lead Source'},
      {'key': 'type', 'label': 'Business Type'},
      {'key': 'priority', 'label': 'Priority'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & Sort',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SORT BY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortOptions.map((option) {
              final isSelected = _currentSort == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentSort = option;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? nec.brand.withValues(alpha: 0.15) : nec.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? nec.brand
                          : nec.separator.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? nec.brand : nec.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'FILTERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: nec.bg,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(filterCategories.length, (index) {
                final cat = filterCategories[index];
                final isLast = index == filterCategories.length - 1;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () {
                        setState(() {
                          _activeView = cat['key']!;
                        });
                      },
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
          ),
          const SizedBox(height: 24),
          NecButton(
            label: 'Apply',
            onPressed: () {
              widget.onSortChanged(_currentSort);
              Navigator.pop(context);
            },
            fullWidth: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatusView(NecColors nec) {
    return Column(
      children: [
        _buildSubHeader('Status'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(statusOptions.length, (index) {
                final item = statusOptions[index];
                final label = item['label'] as String;
                final color = item['color'] as Color;
                final isSelected = _selectedStatuses.contains(label);
                final isLast = index == statusOptions.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleSelection(_selectedStatuses, label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                            _buildCheckbox(isSelected),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NecButton(
            label: 'Apply',
            onPressed: () => Navigator.pop(context),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedView(NecColors nec) {
    final query = _employeeSearchController.text.trim().toLowerCase();
    final filtered = employeeOptions.where((e) {
      if (query.isEmpty) return true;
      final nameStr = e['name']?.toString().toLowerCase() ?? '';
      final desigStr = e['designation']?.toString().toLowerCase() ?? '';
      return nameStr.contains(query) || desigStr.contains(query);
    }).toList();

    return Column(
      children: [
        _buildSubHeader('Assigned Employee'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: nec.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _employeeSearchController,
                    onChanged: (v) => setState(() {}),
                    style: TextStyle(color: nec.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search employee...',
                      hintStyle:
                          TextStyle(color: nec.textTertiary, fontSize: 14),
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(filtered.length, (index) {
                final item = filtered[index];
                final name = item['name'] as String;
                final desig = item['designation'] as String;
                final initials = item['initials'] as String;
                final count = item['count'] as String;
                final isSelected = _selectedEmployees.contains(name);
                final isLast = index == filtered.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleSelection(_selectedEmployees, name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            if (initials != '??')
                              NecAvatar(
                                initials: initials,
                                size: 36,
                              )
                            else
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      nec.textTertiary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.person,
                                  size: 18,
                                  color: nec.textTertiary,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                  if (desig.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desig,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: nec.textTertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (count.isNotEmpty) ...[
                              Text(
                                count,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildCheckbox(isSelected),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.2),
                        indent: 48,
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NecButton(
            label: 'Apply',
            onPressed: () => Navigator.pop(context),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceView(NecColors nec) {
    return Column(
      children: [
        _buildSubHeader('Lead Source'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(sourceOptions.length, (index) {
                final item = sourceOptions[index];
                final isSelected = _selectedSources.contains(item);
                final isLast = index == sourceOptions.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleSelection(_selectedSources, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                            _buildCheckbox(isSelected),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NecButton(
            label: 'Apply',
            onPressed: () => Navigator.pop(context),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeView(NecColors nec) {
    return Column(
      children: [
        _buildSubHeader('Business Type'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(typeOptions.length, (index) {
                final item = typeOptions[index];
                final isSelected = _selectedTypes.contains(item);
                final isLast = index == typeOptions.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleSelection(_selectedTypes, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                            _buildCheckbox(isSelected),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NecButton(
            label: 'Apply',
            onPressed: () => Navigator.pop(context),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityView(NecColors nec) {
    return Column(
      children: [
        _buildSubHeader('Priority'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(priorityOptions.length, (index) {
                final item = priorityOptions[index];
                final label = item['label'] as String;
                final color = item['color'] as Color;
                final isSelected = _selectedPriorities.contains(label);
                final isLast = index == priorityOptions.length - 1;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleSelection(_selectedPriorities, label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                            ),
                            _buildCheckbox(isSelected),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: NecButton(
            label: 'Apply',
            onPressed: () => Navigator.pop(context),
            fullWidth: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: sheetHeight,
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
              const SizedBox(height: 8),
              Expanded(
                child: Builder(
                  builder: (_) {
                    switch (_activeView) {
                      case 'status':
                        return _buildStatusView(nec);
                      case 'assigned':
                        return _buildAssignedView(nec);
                      case 'source':
                        return _buildSourceView(nec);
                      case 'type':
                        return _buildTypeView(nec);
                      case 'priority':
                        return _buildPriorityView(nec);
                      default:
                        return _buildMainView(nec);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
