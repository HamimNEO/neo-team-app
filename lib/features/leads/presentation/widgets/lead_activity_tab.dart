import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class LeadActivityTab extends StatefulWidget {
  const LeadActivityTab({super.key});

  @override
  State<LeadActivityTab> createState() => _LeadActivityTabState();
}

class _LeadActivityTabState extends State<LeadActivityTab> {
  String _selectedFilter = 'All';

  final filterChips = ['All', 'Communication', 'Follow-ups', 'Visits'];

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final todayActivities = [
      {
        'title': 'Follow-up completed',
        'subtitle': 'Client requested an onsite demo.',
        'time': '2:15 PM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.checkmark_alt_circle_fill,
        'color': AppColors.success,
      },
      {
        'title': 'Status changed',
        'subtitle': 'Contacted ➔ Interested',
        'time': '2:16 PM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.arrow_right_arrow_left,
        'color': AppColors.brandLight,
      },
      {
        'title': 'Visit scheduled',
        'subtitle': 'Tomorrow · 11:00 AM — Product demo',
        'time': '2:18 PM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.house_fill,
        'color': AppColors.leadVisit,
      },
      {
        'title': 'Note added',
        'subtitle': '"Client wants a product demo after 4 PM."',
        'time': '11:20 AM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.chat_bubble_fill,
        'color': nec.brand,
      },
    ];

    final yesterdayActivities = [
      {
        'title': 'Lead assigned',
        'subtitle': 'Assigned to Shahina Akter',
        'time': '4:32 PM',
        'author': 'Admin',
        'icon': CupertinoIcons.person_badge_plus_fill,
        'color': AppColors.leadNegotiation,
      },
      {
        'title': 'Follow-up scheduled',
        'subtitle': 'Call · Today 4:00 PM',
        'time': '4:30 PM',
        'author': 'Admin',
        'icon': CupertinoIcons.arrow_turn_down_left,
        'color': AppColors.warning,
      },
    ];

    final sep26Activities = [
      {
        'title': 'Status changed',
        'subtitle': 'New ➔ Contacted',
        'time': '3:05 PM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.arrow_right_arrow_left,
        'color': AppColors.brandLight,
      },
      {
        'title': 'Contacted via phone',
        'subtitle': 'Initial introduction call.',
        'time': '3:00 PM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.phone_fill,
        'color': AppColors.success,
      },
      {
        'title': 'Lead created',
        'subtitle': 'via Facebook',
        'time': '10:12 AM',
        'author': 'Shahina Akter',
        'icon': CupertinoIcons.person_2_fill,
        'color': AppColors.brandLight,
      },
    ];

    Widget buildGroup(String title, List<Map<String, dynamic>> items) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
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
                children: List.generate(items.length, (index) {
                  final act = items[index];
                  final isLast = index == items.length - 1;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: (act['color'] as Color)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                act['icon'] as IconData,
                                size: 16,
                                color: act['color'] as Color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          act['title'] as String,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        act['time'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    act['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: nec.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    act['author'] as String,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: nec.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 60,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = filterChips[index];
                final isSelected = _selectedFilter == chip;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = chip;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? nec.brand : nec.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : nec.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          buildGroup('TODAY', todayActivities),
          buildGroup('YESTERDAY', yesterdayActivities),
          buildGroup('SEP 26', sep26Activities),
          GestureDetector(
            onTap: () {
              NecToast.show(
                context,
                message: 'Add note to activity coming soon',
                type: NecToastType.info,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nec.brand.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chat_bubble, size: 16, color: nec.brand),
                  const SizedBox(width: 8),
                  Text(
                    'Add a note to activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
