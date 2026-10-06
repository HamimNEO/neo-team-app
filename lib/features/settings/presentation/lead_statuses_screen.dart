import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';

class StatusItem {
  final String name;
  final String badge;
  final Color color;
  bool isEnabled;

  StatusItem({
    required this.name,
    this.badge = 'SYSTEM',
    required this.color,
    this.isEnabled = true,
  });
}

class LeadStatusesScreen extends StatefulWidget {
  const LeadStatusesScreen({super.key});

  @override
  State<LeadStatusesScreen> createState() => _LeadStatusesScreenState();
}

class _LeadStatusesScreenState extends State<LeadStatusesScreen> {
  late List<StatusItem> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = [
      StatusItem(name: 'New', color: AppColors.brandLight),
      StatusItem(name: 'Assigned', color: const Color(0xFF5856D6)),
      StatusItem(name: 'Contacted', color: const Color(0xFF30B0C7)),
      StatusItem(name: 'Interested', color: AppColors.warning),
      StatusItem(name: 'Follow-up', color: const Color(0xFFFF9500)),
      StatusItem(name: 'Visit Scheduled', color: AppColors.leadContacted),
      StatusItem(name: 'Negotiation', color: const Color(0xFFAF52DE)),
      StatusItem(name: 'Won', color: AppColors.success),
      StatusItem(name: 'Lost', color: AppColors.error),
    ];
  }

  void _openAddStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddStatusSheet(
        existingStatuses: _statuses.map((s) => s.name).toList(),
        onAdded: (name, color, placeAfter) {
          setState(() {
            final newItem =
                StatusItem(name: name, badge: 'CUSTOM', color: color);
            if (placeAfter == '— End of list' || placeAfter.isEmpty) {
              _statuses.add(newItem);
            } else {
              final idx = _statuses.indexWhere((s) => s.name == placeAfter);
              if (idx != -1) {
                _statuses.insert(idx + 1, newItem);
              } else {
                _statuses.add(newItem);
              }
            }
          });
          NecToast.show(
            context,
            message: 'Status "$name" added successfully',
            type: NecToastType.success,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
                  'Lead Statuses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(CupertinoIcons.add, color: nec.brand, size: 22),
                onPressed: _openAddStatusSheet,
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
              Text(
                'The status lifecycle defines how leads progress. System statuses cannot be removed.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: nec.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIFECYCLE PREVIEW',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: List.generate(_statuses.length, (idx) {
                        final s = _statuses[idx];
                        final isLast = idx == _statuses.length - 1;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: s.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: s.color,
                                ),
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 4),
                              Text(
                                '›',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(_statuses.length, (index) {
                    final item = _statuses[index];
                    final isLast = index == _statuses.length - 1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
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
                                  item.badge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: item.badge == 'CUSTOM'
                                        ? AppColors.warning
                                        : nec.textSecondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: item.isEnabled,
                                activeTrackColor: AppColors.success,
                                onChanged: (val) {
                                  setState(() {
                                    item.isEnabled = val;
                                  });
                                },
                              ),
                            ],
                          ),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStatusSheet extends StatefulWidget {
  final List<String> existingStatuses;
  final Function(String name, Color color, String placeAfter) onAdded;

  const _AddStatusSheet({
    required this.existingStatuses,
    required this.onAdded,
  });

  @override
  State<_AddStatusSheet> createState() => _AddStatusSheetState();
}

class _AddStatusSheetState extends State<_AddStatusSheet> {
  final _nameController = TextEditingController();
  final List<Color> _colors = [
    AppColors.brandLight,
    const Color(0xFF5856D6),
    const Color(0xFF30B0C7),
    AppColors.warning,
    const Color(0xFFFF9500),
    const Color(0xFFAF52DE),
    AppColors.success,
    AppColors.error,
    const Color(0xFFFF2D55),
  ];
  late Color _selectedColor;
  late String _selectedPlaceAfter;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colors.first;
    _selectedPlaceAfter = '— End of list';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a status name',
        type: NecToastType.error,
      );
      return;
    }
    widget.onAdded(name, _selectedColor, _selectedPlaceAfter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final placeAfterOptions = ['— End of list', ...widget.existingStatuses];

    return Material(
      color: nec.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Add Status',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'STATUS NAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Proposal Sent',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'STATUS COLOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((c) {
                  final isSel = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                      child: isSel
                          ? const Icon(
                              CupertinoIcons.checkmark,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'PLACE AFTER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? nec.bg : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlaceAfter,
                    isExpanded: true,
                    dropdownColor: isDark ? nec.surface : Colors.white,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                    icon: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: nec.textTertiary,
                    ),
                    items: placeAfterOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPlaceAfter = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              NecButton(
                label: 'Add Status',
                onPressed: _submit,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
