import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeActivityTab extends StatefulWidget {
  const EmployeeActivityTab({super.key});

  @override
  State<EmployeeActivityTab> createState() => _EmployeeActivityTabState();
}

class _EmployeeActivityTabState extends State<EmployeeActivityTab> {
  String _selectedFilter = 'All';

  final filterOptions = [
    'All',
    'Leads',
    'Follow-ups',
    'Visits',
    'Tasks',
    'Issues'
  ];

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final allActivities = {
      'TODAY': [
        {
          'title': 'Follow-up completed',
          'subtitle': 'Blue Wave Resort',
          'detail': 'Result: Interested',
          'time': '2:15 PM',
          'category': 'Follow-ups',
          'icon': CupertinoIcons.arrow_turn_down_left,
          'color': AppColors.success,
        },
        {
          'title': 'Lead status updated',
          'subtitle': 'Interested → Negotiation',
          'detail': 'Ocean Nest Hotel',
          'time': '11:40 AM',
          'category': 'Leads',
          'icon': CupertinoIcons.person_2,
          'color': AppColors.brandLight,
        },
        {
          'title': 'Note added',
          'subtitle': 'Blue Wave Resort',
          'detail': null,
          'time': '10:05 AM',
          'category': 'Leads',
          'icon': CupertinoIcons.doc_text,
          'color': AppColors.warning,
        },
      ],
      'YESTERDAY': [
        {
          'title': 'Visit completed',
          'subtitle': 'Green Palm Hotel',
          'detail': 'Outcome: Interested',
          'time': '4:20 PM',
          'category': 'Visits',
          'icon': CupertinoIcons.house_fill,
          'color': AppColors.leadVisit,
        },
        {
          'title': 'Lead assigned',
          'subtitle': 'Sea Pearl Resort',
          'detail': null,
          'time': '9:30 AM',
          'category': 'Leads',
          'icon': CupertinoIcons.person_2,
          'color': AppColors.brandLight,
        },
      ],
      'MON, 22 SEP': [
        {
          'title': 'Task completed',
          'subtitle': 'Prepare proposal for Blue Wave',
          'detail': null,
          'time': '3:10 PM',
          'category': 'Tasks',
          'icon': CupertinoIcons.checkmark_rectangle,
          'color': AppColors.leadContacted,
        },
        {
          'title': 'Follow-up completed',
          'subtitle': 'Ocean Nest Hotel',
          'detail': 'Result: Call Later',
          'time': '1:00 PM',
          'category': 'Follow-ups',
          'icon': CupertinoIcons.arrow_turn_down_left,
          'color': AppColors.success,
        },
      ],
      'FRI, 19 SEP': [
        {
          'title': 'Lead status updated',
          'subtitle': 'New → Contacted',
          'detail': 'Sunrise Guest House',
          'time': '11:15 AM',
          'category': 'Leads',
          'icon': CupertinoIcons.person_2,
          'color': AppColors.brandLight,
        },
      ],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final isSelected = _selectedFilter == option;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = option;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? nec.brand.withValues(alpha: 0.15)
                          : nec.surface,
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
                        color: isSelected ? nec.brand : nec.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ...allActivities.entries.map((group) {
            final dateTitle = group.key;
            final items = group.value.where((item) {
              if (_selectedFilter == 'All') return true;
              return item['category'] == _selectedFilter;
            }).toList();

            if (items.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isLast = index == items.length - 1;
                        final color = item['color'] as Color;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => context.push('/leads/lead_1'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: nec.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['subtitle'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: nec.textSecondary,
                                            ),
                                          ),
                                          if (item['detail'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item['detail'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: nec.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item['time'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: nec.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: nec.separator.withValues(alpha: 0.3),
                                indent: 66,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
