import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'add_lead_picker_sheet.dart';

class LeadOverviewTab extends StatefulWidget {
  final bool isUnassigned;
  final String companyName;

  const LeadOverviewTab({
    super.key,
    this.isUnassigned = true,
    required this.companyName,
  });

  @override
  State<LeadOverviewTab> createState() => _LeadOverviewTabState();
}

class _LeadOverviewTabState extends State<LeadOverviewTab> {
  late bool _unassigned;
  String _assignedEmployee = 'Unassigned';

  @override
  void initState() {
    super.initState();
    _unassigned = widget.isUnassigned;
  }

  void _openChangeEmployeeSheet() {
    if (!DemoSession.instance.isAdmin) {
      NecToast.show(
        context,
        message: 'Only administrators can reassign leads to other team members',
        type: NecToastType.info,
      );
      return;
    }
    final employees = [
      {'label': 'Shahina Akter'},
      {'label': 'Rahul Mehta'},
      {'label': 'Priya Das'},
      {'label': 'Fahim Ahmed'},
      {'label': 'Unassigned'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Assigned Employee',
        options: employees,
        selectedValue: _assignedEmployee,
        onSelected: (val) {
          setState(() {
            _assignedEmployee = val as String;
            _unassigned = (val == 'Unassigned');
          });
          NecToast.show(
            context,
            message: 'Lead assigned to $_assignedEmployee',
            type: NecToastType.success,
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRowItem({
    required BuildContext context,
    required String label,
    required Widget valueWidget,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textTertiary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    valueWidget,
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: nec.separator.withValues(alpha: 0.2),
            indent: 16,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'CONTACT'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Person',
                  valueWidget: Text(
                    'Arif Khan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Phone',
                  valueWidget: Text(
                    'Call',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.brand,
                    ),
                  ),
                  onTap: () {
                    NecToast.show(
                      context,
                      message: 'Calling Arif Khan (+8801711-111222)...',
                      type: NecToastType.info,
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'BUSINESS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Company',
                  valueWidget: Text(
                    widget.companyName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Type',
                  valueWidget: Text(
                    'Resort',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Location',
                  valueWidget: Text(
                    "Cox's Bazar",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'BUSINESS PROFILE'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                '+ Add qualification details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
              onTap: () => context.push('/edit-lead/lead_1'),
            ),
          ),
          _buildSectionHeader(context, 'LEAD'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Status',
                  valueWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.brandLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'New',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {},
                ),
                _buildRowItem(
                  context: context,
                  label: 'Source',
                  valueWidget: Text(
                    'Facebook',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Priority',
                  valueWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Normal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandLight,
                      ),
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Created',
                  valueWidget: Text(
                    '1h ago',
                    style: TextStyle(
                      fontSize: 14,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Updated',
                  valueWidget: Text(
                    '1h ago',
                    style: TextStyle(
                      fontSize: 14,
                      color: nec.textPrimary,
                    ),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'OWNERSHIP'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _unassigned ? 'Unassigned' : _assignedEmployee,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _unassigned
                                ? AppColors.warning
                                : nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _unassigned
                              ? 'No employee assigned'
                              : 'Assigned employee',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (DemoSession.instance.isAdmin)
                    TextButton(
                      onPressed: _openChangeEmployeeSheet,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildSectionHeader(context, 'NEXT ACTION'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(
                  color: AppColors.warning,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'SCHEDULED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today · 4:00 PM',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Discuss product demo',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            NecToast.show(
                              context,
                              message: 'Call marked completed',
                              type: NecToastType.success,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.success.withValues(alpha: 0.15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            NecToast.show(
                              context,
                              message: 'Reschedule coming soon',
                              type: NecToastType.info,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nec.bg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Reschedule',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'LATEST NOTE'),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Text(
                  'All Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: nec.brand,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Client wants a product demo after 4 PM. Seems genuinely interested in the enterprise package."',
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Shahina Akter · Today 11:20 AM',
                  style: TextStyle(
                    fontSize: 12,
                    color: nec.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                NecToast.show(
                  context,
                  message: 'Add note coming soon',
                  type: NecToastType.info,
                );
              },
              icon: Icon(CupertinoIcons.add, size: 16, color: nec.brand),
              label: Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: nec.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: nec.separator.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
