import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/services/phone_service.dart';
import '../../../core/services/staff_access_store.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/lead_store.dart';
import '../../team/data/employee_store.dart';
import 'widgets/lead_assignee_picker.dart';
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
  bool _reassigning = false;

  bool get _isUnassigned {
    final lead = LeadStore.instance.byId(widget.leadId);
    return lead == null ||
        (lead.assignedEmployeeId == null && lead.assignedTo == null);
  }

  String get _assignedEmployee {
    final lead = LeadStore.instance.byId(widget.leadId);
    return lead == null ? 'Unassigned' : LeadStore.instance.assigneeName(lead);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    LeadStore.instance.addListener(_refresh);
    EmployeeStore.instance.addListener(_refresh);
    EmployeeStore.instance.load();
    LeadStore.instance.fetchDetails(widget.leadId, force: true);
  }

  @override
  void dispose() {
    LeadStore.instance.removeListener(_refresh);
    EmployeeStore.instance.removeListener(_refresh);
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openAssignEmployeeSheet() async {
    if (_reassigning || !DemoSession.instance.isAdmin) return;
    final actor = DemoSession.instance.employeeId;
    _reassigning = true;
    try {
      final lead = LeadStore.instance.byId(widget.leadId);
      final selected =
          await chooseLeadAssignee(context, lead?.assignedEmployeeId);
      if (!mounted ||
          selected == null ||
          !DemoSession.instance.isAdmin ||
          DemoSession.instance.employeeId != actor) {
        return;
      }
      await LeadStore.instance
          .reassign(widget.leadId, selected.isEmpty ? null : selected);
      if (mounted) {
        NecToast.show(context, message: 'Lead assigned to $_assignedEmployee');
      }
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message
                : 'Unable to change this assignment. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      _reassigning = false;
    }
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
            'The CRM backend does not allow deleting lead records permanently (API 405 Method Not Allowed).\n\nWould you like to mark this lead as "Lost" instead?',
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
            onPressed: () async {
              Navigator.pop(ctx);
              await LeadStore.instance.updateStatus(widget.leadId, 'Lost');
              if (mounted) {
                context.pop();
                NecToast.show(
                  context,
                  message: '$companyName marked as Lost',
                  type: NecToastType.info,
                );
              }
            },
            child: const Text('Mark as Lost'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final lead = LeadStore.instance.byId(widget.leadId);
    final companyName = lead?.company ?? 'Lead';
    final details = LeadStore.instance.getDetails(widget.leadId);
    final work = details?['work'] as Map? ?? {};
    final followups = (work['followups'] as List? ?? []);
    final visits = (work['visits'] as List? ?? []);
    final tasks = (work['tasks'] as List? ?? []);
    final pendingCount = followups.length +
        visits.length +
        tasks.where((t) => t['status']?.toString() != 'completed').length;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        leadingWidth: 76,
        titleSpacing: 8,
        centerTitle: true,
        leading: CupertinoButton(
          padding: const EdgeInsets.only(left: 12, right: 4),
          onPressed: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.chevron_left,
                size: 16,
                color: nec.brand,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  'Back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nec.brand,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Tooltip(
          message: companyName,
          child: Text(
            companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: nec.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          if (lead?.phone != null && lead!.phone!.trim().isNotEmpty)
            IconButton(
              tooltip: 'Call contact',
              onPressed: () => PhoneService.call(context, lead.phone!),
              icon: const Icon(CupertinoIcons.phone_fill, size: 18),
              color: AppColors.success,
            ),
          IconButton(
            tooltip: 'Lead actions',
            onPressed: DemoSession.instance.isAdmin ||
                    StaffAccessStore.instance.allows(StaffPermission.editLead)
                ? () => _openActionSheet(companyName)
                : null,
            icon: const Icon(CupertinoIcons.ellipsis, size: 20),
            color: nec.brand,
          ),
          const SizedBox(width: 4),
        ],
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  const Tab(text: 'Overview', height: 44),
                  const Tab(text: 'Activity', height: 44),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Work'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: nec.brand,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'More', height: 44),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  LeadOverviewTab(
                    lead: lead,
                    details: details,
                    isUnassigned: _isUnassigned,
                    assignedEmployee: _assignedEmployee,
                    onChangeAssigned: _openAssignEmployeeSheet,
                    companyName: companyName,
                    location: lead?.location,
                    leadType: lead?.type,
                    latitude: lead?.latitude,
                    longitude: lead?.longitude,
                  ),
                  LeadActivityTab(
                    leadId: widget.leadId,
                    activities: (details?['activity'] as List? ?? []),
                  ),
                  LeadWorkTab(
                    leadId: widget.leadId,
                    work: Map<String, dynamic>.from(work),
                  ),
                  LeadMoreTab(
                    leadId: widget.leadId,
                    notes: (details?['notes'] as List? ?? []),
                    attachments: (details?['attachments'] as List? ?? []),
                    activities: (details?['activity'] as List? ?? []),
                  ),
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
