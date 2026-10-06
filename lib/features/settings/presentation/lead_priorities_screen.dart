import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class PrioritySettingItem {
  final String name;
  final Color color;
  final String badge;
  bool isEnabled;

  PrioritySettingItem({
    required this.name,
    required this.color,
    this.badge = 'SYSTEM',
    this.isEnabled = true,
  });
}

class LeadPrioritiesScreen extends StatefulWidget {
  const LeadPrioritiesScreen({super.key});

  @override
  State<LeadPrioritiesScreen> createState() => _LeadPrioritiesScreenState();
}

class _LeadPrioritiesScreenState extends State<LeadPrioritiesScreen> {
  late List<PrioritySettingItem> _priorities;

  @override
  void initState() {
    super.initState();
    _priorities = [
      PrioritySettingItem(name: 'Low', color: AppColors.success),
      PrioritySettingItem(name: 'Normal', color: AppColors.brandLight),
      PrioritySettingItem(name: 'High', color: AppColors.warning),
      PrioritySettingItem(name: 'Urgent', color: AppColors.error),
    ];
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
                  'Lead Priorities',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
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
                'System-defined priorities for lead urgency. Used for sorting and notification triggers.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: nec.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(_priorities.length, (index) {
                    final item = _priorities[index];
                    final isLast = index == _priorities.length - 1;

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
                                    color: nec.textSecondary,
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
