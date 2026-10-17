import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'add_lead_note_sheet.dart';

class LeadActivityTab extends StatefulWidget {
  final String leadId;
  final List<dynamic> activities;

  const LeadActivityTab({
    super.key,
    required this.leadId,
    this.activities = const [],
  });

  @override
  State<LeadActivityTab> createState() => _LeadActivityTabState();
}

class _LeadActivityTabState extends State<LeadActivityTab> {
  String _selectedFilter = 'All';
  final filterChips = ['All', 'Notes', 'Lifecycle', 'Work'];

  void _openAddNoteDialog() {
    showLeadNoteSheet(
      context,
      leadId: widget.leadId,
      title: 'Add Activity Note',
      hintText: 'Enter note to record in activity feed...',
    );
  }

  IconData _iconForEvent(String event) {
    final ev = event.toLowerCase();
    if (ev.contains('note')) return CupertinoIcons.chat_bubble_fill;
    if (ev.contains('assign')) return CupertinoIcons.person_badge_plus_fill;
    if (ev.contains('visit')) return CupertinoIcons.map_pin_ellipse;
    if (ev.contains('follow')) return CupertinoIcons.clock_fill;
    if (ev.contains('create')) return CupertinoIcons.plus_circle_fill;
    if (ev.contains('update') || ev.contains('status')) {
      return CupertinoIcons.arrow_2_circlepath;
    }
    return CupertinoIcons.bolt_fill;
  }

  Color _colorForEvent(String event, NecColors nec) {
    final ev = event.toLowerCase();
    if (ev.contains('note')) return nec.brand;
    if (ev.contains('assign')) return const Color(0xFF7C3AED);
    if (ev.contains('visit')) return const Color(0xFF0D9488);
    if (ev.contains('follow')) return AppColors.warning;
    if (ev.contains('create')) return AppColors.success;
    if (ev.contains('update') || ev.contains('status')) {
      return AppColors.brandLight;
    }
    return nec.brand;
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final allActivities = widget.activities.whereType<Map>().map((m) {
      return Map<String, dynamic>.from(m);
    }).toList();

    final filtered = allActivities.where((item) {
      if (_selectedFilter == 'All') return true;
      final event = (item['event']?.toString() ?? '').toLowerCase();
      if (_selectedFilter == 'Notes') return event.contains('note');
      if (_selectedFilter == 'Lifecycle') {
        return event.contains('create') ||
            event.contains('update') ||
            event.contains('status') ||
            event.contains('assign');
      }
      if (_selectedFilter == 'Work') {
        return event.contains('visit') ||
            event.contains('follow') ||
            event.contains('task');
      }
      return true;
    }).toList();

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
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 40,
                    color: nec.textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No activities recorded yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Notes, assignments, and updates will be logged here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(filtered.length, (index) {
                  final item = filtered[index];
                  final isLast = index == filtered.length - 1;
                  final event = item['event']?.toString() ?? 'Activity';
                  final desc =
                      item['description']?.toString() ?? 'Lead activity';
                  final actor = item['actor']?['name']?.toString() ?? 'Admin';
                  final time = _formatTime(item['occurred_at']?.toString());
                  final icon = _iconForEvent(event);
                  final color = _colorForEvent(event, nec);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18),
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
                                          desc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    actor,
                                    style: TextStyle(
                                      fontSize: 12,
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
                          indent: 64,
                        ),
                    ],
                  );
                }),
              ),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _openAddNoteDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nec.brand.withValues(alpha: 0.5),
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
