import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import 'widgets/add_lead_picker_sheet.dart';
import 'widgets/lead_activity_tab.dart';
import 'widgets/lead_more_tab.dart';
import 'widgets/lead_overview_tab.dart';
import 'widgets/lead_work_tab.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;

  const LeadDetailsScreen({
    super.key,
    required this.leadId,
  });

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isUnassigned;
  String _assignedEmployee = 'Unassigned';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isUnassigned = widget.leadId == 'lead_3' || widget.leadId == 'lead_4';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAssignEmployeeSheet() {
    if (!DemoSession.instance.isAdmin) {
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
        title: 'Assign Lead To',
        options: employees,
        selectedValue: _assignedEmployee,
        onSelected: (val) {
          setState(() {
            _assignedEmployee = val as String;
            _isUnassigned = (val == 'Unassigned');
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

  void _openActionSheet(String companyName) {
    final nec = Theme.of(context).extension<NecColors>()!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              if (StaffAccessStore.instance.allows(StaffPermission.editLead))
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/edit-lead/${widget.leadId}');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Edit Lead',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: nec.brand,
                      ),
                    ),
                  ),
                ),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              if (DemoSession.instance.isAdmin)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAssignEmployeeSheet();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Assign Lead',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                  ),
                ),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
              if (DemoSession.instance.isAdmin)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(companyName);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Delete Lead',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String companyName) {
    if (!DemoSession.instance.isAdmin) {
      return;
    }
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete $companyName?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'This lead and its history will be permanently deleted.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              NecToast.show(
                context,
                message: '$companyName deleted',
                type: NecToastType.info,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final companyName = (widget.leadId == 'lead_4')
        ? 'Coral Reef Resort'
        : (widget.leadId == 'lead_3'
            ? 'Ocean Paradise Hotel'
            : 'Sea Pearl Resort');

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
                onPressed: () => context.pop(),
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
                  companyName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: DemoSession.instance.isAdmin ||
                        StaffAccessStore.instance
                            .allows(StaffPermission.editLead)
                    ? () => _openActionSheet(companyName)
                    : null,
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: nec.separator.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: nec.brand,
                unselectedLabelColor: nec.textTertiary,
                indicatorColor: nec.brand,
                indicatorWeight: 2,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  const Tab(text: 'Overview'),
                  const Tab(text: 'Activity'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Work'),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: nec.brand,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'More'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  LeadOverviewTab(
                    isUnassigned: _isUnassigned,
                    companyName: companyName,
                  ),
                  const LeadActivityTab(),
                  const LeadWorkTab(),
                  LeadMoreTab(leadId: widget.leadId),
                ],
              ),
            ),
            if (_isUnassigned && DemoSession.instance.isAdmin)
              Padding(
                padding: const EdgeInsets.all(16),
                child: NecButton(
                  label: 'Assign Lead',
                  onPressed: _openAssignEmployeeSheet,
                  fullWidth: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
