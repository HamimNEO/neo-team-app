import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
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

  void _handleMainAction(String leadName) {
    if (_visitState == VisitState.startJourney) {
      setState(() {
        _visitState = VisitState.markArrived;
      });
      NecToast.show(
        context,
        message: 'Journey started for visit',
        type: NecToastType.info,
      );
    } else if (_visitState == VisitState.markArrived) {
      setState(() {
        _visitState = VisitState.completeVisit;
      });
      NecToast.show(
        context,
        message: 'Marked arrived at site',
        type: NecToastType.success,
      );
    } else {
      _openVisitReportSheet(leadName);
    }
  }

  void _openVisitReportSheet(String leadName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VisitReportSheet(
        leadName: leadName,
        onSaved: () {
          context.pop();
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
            onPressed: () {
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

    final isGreenPalm = widget.visitId == 'visit_002';

    const dateText = 'Today';
    final timeText = isGreenPalm ? '3:30 PM' : '11:00 AM';
    final locationText =
        isGreenPalm ? 'Sugandha, Cox\'s Bazar' : 'Kolatoli, Cox\'s Bazar';
    final purposeText = isGreenPalm ? 'Initial site meeting' : 'Product demo';

    final assigneeName = isGreenPalm ? 'Yeapas' : 'Shahina Akter';
    final assigneeInitials = isGreenPalm ? 'Y' : 'SA';

    final contactName = isGreenPalm ? 'Jabbar Mia' : 'Rahim Ahmed';
    final contactInitials = isGreenPalm ? 'J' : 'R';
    final contactPhone = isGreenPalm ? '01811-333333' : '017XX-XXX-XXX';

    final leadId = isGreenPalm ? 'lead_2' : 'lead_1';
    final leadName = isGreenPalm ? 'Green Palm Hotel' : 'Blue Wave Resort';
    final leadStatus = isGreenPalm ? 'Visit Scheduled' : 'Interested';
    final leadStatusColor =
        isGreenPalm ? AppColors.leadVisit : AppColors.leadInterested;

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
                onPressed: () => _openVisitOptionsSheet(leadId),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: nec.brand,
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
                      onTap: () {
                        NecToast.show(
                          context,
                          message: 'Calling $contactName ($contactPhone)...',
                          type: NecToastType.info,
                        );
                      },
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
                                decoration: BoxDecoration(
                                  color: leadStatusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                leadStatus,
                                style: TextStyle(
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
                  onTap: () => context.push('/leads/$leadId'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _handleMainAction(leadName),
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
                        onPressed: () {
                          NecToast.show(
                            context,
                            message: 'Reschedule coming soon',
                            type: NecToastType.info,
                          );
                        },
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
                        child: Text(
                          'Reschedule',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.brand,
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
                        onPressed: _confirmCancelVisit,
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
                        child: Text(
                          'Cancel Visit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
