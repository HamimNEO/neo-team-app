import 'widgets/work_delivery_details.dart';
import '../../../core/services/phone_service.dart';
import 'widgets/reschedule_follow_up_sheet.dart';
import '../data/work_queue_mapper.dart';
import '../../team/domain/models/employee.dart';
import '../../leads/data/lead_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../tasks/data/work_item_store.dart';
import '../../../core/services/demo_session.dart';
import '../../team/data/employee_store.dart';
import 'widgets/visit_map_view_sheet.dart';
import 'widgets/visit_options_sheet.dart';
import 'widgets/visit_report_sheet.dart';

enum VisitState { startJourney, markArrived, completeVisit }

class VisitDetailsScreen extends StatefulWidget {
  final String visitId;

  const VisitDetailsScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  VisitState _visitState = VisitState.startJourney;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WorkItemStore.instance.addListener(_refresh);
    WorkItemStore.instance
        .fetchDetails(widget.visitId, type: 'visit')
        .catchError((error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
      return <String, dynamic>{};
    });
  }

  void _refresh() {
    if (!mounted) return;
    final actions =
        WorkItemStore.instance.byId(widget.visitId)?.metadata['actions'];
    setState(() {
      _visitState = actions is Map && actions['can_complete'] == true
          ? VisitState.completeVisit
          : actions is Map && actions['can_mark_arrived'] == true
              ? VisitState.markArrived
              : VisitState.startJourney;
    });
  }

  @override
  void dispose() {
    WorkItemStore.instance.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _handleMainAction(String leadName) async {
    if (_working) return;
    if (_visitState == VisitState.completeVisit) {
      _openVisitReportSheet(leadName);
      return;
    }
    setState(() => _working = true);
    try {
      if (_visitState == VisitState.startJourney) {
        await WorkItemStore.instance.startVisitJourney(widget.visitId);
      } else {
        await WorkItemStore.instance.markVisitArrived(widget.visitId);
      }
      if (mounted) {
        NecToast.show(context,
            message: 'Visit updated successfully', type: NecToastType.success);
      }
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: WorkItemStore.messageFor(error), type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _openVisitReportSheet(String leadName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VisitReportSheet(
        leadName: leadName,
        onSubmit: (payload) =>
            WorkItemStore.instance.completeVisitReport(widget.visitId, payload),
        onSaved: () {
          if (mounted) context.pop();
        },
      ),
    );
  }

  void _openVisitOptionsSheet(String leadId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VisitOptionsSheet(
        leadId: leadId,
        visitId: widget.visitId,
      ),
    );
  }

  void _openMapViewSheet(String locationName, String leadName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VisitMapViewSheet(
        locationName: locationName,
        leadName: leadName,
      ),
    );
  }

  void _confirmCancelVisit() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cancel Visit?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'This scheduled visit will be cancelled.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await WorkItemStore.instance
                    .cancelVisit(widget.visitId, 'Cancelled from app');
              } catch (error) {
                if (ctx.mounted) {
                  NecToast.show(ctx,
                      message: WorkItemStore.messageFor(error),
                      type: NecToastType.error);
                }
                return;
              }
              if (!ctx.mounted || !mounted) return;
              Navigator.pop(ctx);
              context.pop();
              NecToast.show(
                context,
                message: 'Visit cancelled',
                type: NecToastType.info,
              );
            },
            child: const Text('Cancel Visit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final item = WorkItemStore.instance.byId(widget.visitId);
    final contact = item?.metadata['contact_person'] is Map
        ? item!.metadata['contact_person'] as Map
        : {};
    final actions = item?.metadata['actions'] is Map
        ? item!.metadata['actions'] as Map
        : {};
    final leadId = item?.leadId ?? '';
    final lead = LeadStore.instance.byId(leadId);
    final dateText = WorkQueueMapper.date(item?.scheduledAt);
    final timeText = WorkQueueMapper.time(item?.scheduledAt);
    final locationText =
        item?.metadata['location']?.toString() ?? item?.leadLocation ?? '';
    final purposeText =
        item?.metadata['purpose']?.toString() ?? item?.title ?? '';
    final assigneeName = item?.assigneeName ?? 'Unassigned';
    final assigneeInitials = Employee.initialsFor(assigneeName);
    final contactName =
        (contact['name'] ?? lead?.contactName ?? 'Not provided').toString();
    final contactInitials = Employee.initialsFor(contactName);
    final contactPhone = (contact['phone'] ?? lead?.phone ?? '').toString();
    final leadName = item?.leadName ?? item?.title ?? 'Visit';
    final leadStatus = lead?.status ?? '';
    const leadStatusColor = AppColors.leadVisit;

    final isAdmin = DemoSession.instance.isAdmin;
    final currentEmp = EmployeeStore.instance.currentEmployee;
    final isAssignee = (item?.assigneeName != null &&
            item!.assigneeName!.isNotEmpty &&
            item.assigneeName!.toLowerCase() ==
                currentEmp.name.toLowerCase()) ||
        (item?.assigneeEmployeeId != null &&
            item!.assigneeEmployeeId!.toString().replaceFirst('api_emp_', '') ==
                currentEmp.backendId);
    final canConductVisit = isAdmin || isAssignee;

    final isDoneOrCancelled = item != null &&
        (item.isCompleted ||
            item.status.toLowerCase() == 'completed' ||
            item.status.toLowerCase() == 'cancelled');
    final canReschedule = canConductVisit &&
        !isDoneOrCancelled &&
        actions['can_reschedule'] != false;
    final canCancel =
        canConductVisit && !isDoneOrCancelled && actions['can_cancel'] != false;

    String buttonText;
    Color buttonColor;

    switch (_visitState) {
      case VisitState.startJourney:
        buttonText = 'Start Journey';
        buttonColor = AppColors.warning;
        break;
      case VisitState.markArrived:
        buttonText = 'Mark Arrived';
        buttonColor = const Color(0xFFBF5AF2);
        break;
      case VisitState.completeVisit:
        buttonText = 'Complete Visit';
        buttonColor = AppColors.success;
        break;
    }

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
                  'Visit',
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
                onPressed: canConductVisit
                    ? () => _openVisitOptionsSheet(leadId)
                    : null,
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: canConductVisit ? nec.brand : nec.textTertiary,
                ),
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
              WorkDeliveryDetails(metadata: item?.metadata ?? const {}),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 14,
                                color: nec.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 14,
                                color: nec.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nec.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _openMapViewSheet(locationText, leadName),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: nec.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: nec.brand.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.location_fill,
                          size: 14,
                          color: nec.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                      'Purpose',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      purposeText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: nec.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: NecAvatar(
                        initials: assigneeInitials,
                        size: 38,
                      ),
                      title: Text(
                        'Assigned To',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      subtitle: Text(
                        assigneeName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.3),
                      indent: 16,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            contactInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Contact at Site',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contactName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contactPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: nec.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.phone_fill,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      onTap: contactPhone.isEmpty
                          ? null
                          : () => PhoneService.call(context, contactPhone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'LEAD',
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
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_2,
                      color: AppColors.brandLight,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    leadName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: leadStatusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: leadStatusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                leadStatus,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: leadStatusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: nec.textTertiary,
                  ),
                  onTap: leadId.isEmpty
                      ? null
                      : () => context.push('/leads/$leadId'),
                ),
              ),
              const SizedBox(height: 24),
              if (!canConductVisit) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: nec.separator.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.neutral.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.lock_shield_fill,
                          size: 20,
                          color: AppColors.neutral,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item?.assigneeName == null ||
                                      item!.assigneeName == 'Unassigned'
                                  ? 'Visit Unassigned'
                                  : 'Assigned to ${item.assigneeName}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item?.assigneeName == null ||
                                      item!.assigneeName == 'Unassigned'
                                  ? 'An administrator must assign a team member before starting this journey.'
                                  : 'Only ${item.assigneeName} or an administrator can start the journey and conduct this visit.',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _working ||
                            !(actions['can_start_journey'] == true ||
                                actions['can_mark_arrived'] == true ||
                                actions['can_complete'] == true)
                        ? null
                        : () => _handleMainAction(leadName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: !canReschedule
                              ? null
                              : () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => RescheduleFollowUpSheet(
                                      title: 'Reschedule Visit',
                                      currentSchedule: '$dateText $timeText',
                                      leadName: leadName,
                                      onSave: (date, time) => WorkItemStore
                                          .instance
                                          .rescheduleVisit(
                                              widget.visitId, date, time))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nec.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: canReschedule
                                    ? nec.brand.withValues(alpha: 0.5)
                                    : nec.separator.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text(
                            'Reschedule',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  canReschedule ? nec.brand : nec.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: canCancel ? _confirmCancelVisit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nec.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: canCancel
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : nec.separator.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel Visit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: canCancel
                                  ? AppColors.error
                                  : nec.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
