import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/visit.dart';
import 'select_lead_sheet.dart';

class ScheduleVisitSheet extends StatefulWidget {
  final String? initialLeadName;

  const ScheduleVisitSheet({
    super.key,
    this.initialLeadName,
  });

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  late String _selectedLead;
  String _selectedDate = 'Tomorrow';
  String _selectedTime = '11:00 AM';
  final _locationController = TextEditingController(text: "Cox's Bazar");
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLead = widget.initialLeadName ?? 'Blue Wave Resort';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _openLeadPicker() async {
    final lead = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SelectLeadSheet(currentLeadName: _selectedLead),
    );
    if (lead != null && lead.isNotEmpty) {
      setState(() {
        _selectedLead = lead;
      });
    }
  }

  void _submitVisit() {
    final purpose = _purposeController.text.trim().isEmpty
        ? 'Product demo, site meeting'
        : _purposeController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? "Cox's Bazar"
        : _locationController.text.trim();

    final newVisit = Visit(
      id: 'v_${DateTime.now().millisecondsSinceEpoch % 1000}',
      leadName: _selectedLead,
      location: location,
      purpose: purpose,
      dateText: _selectedDate,
      timeText: _selectedTime,
      assigneeName: 'Shahina Akter',
      assigneeInitials: 'S',
      status: 'Scheduled',
      statusGroup: _selectedDate == 'Today'
          ? 'Today'
          : _selectedDate == 'Tomorrow'
              ? 'Tomorrow'
              : 'This Week',
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newVisit);
    }

    NecToast.show(
      context,
      message: 'Visit scheduled successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: nec.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: nec.bg,
        appBar: AppBar(
          backgroundColor: nec.bg,
          elevation: 0,
          toolbarHeight: 52,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Column(
            children: [
              const SizedBox(height: 6),
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
              const SizedBox(height: 8),
              Text(
                'Schedule Visit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _openLeadPicker,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? nec.surface
                                  : nec.separator.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    AppColors.brandLight.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandLight
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: AppColors.brandLight,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedLead,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: nec.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Lead · tap to change',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Change',
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
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate =
                                            _selectedDate == 'Tomorrow'
                                                ? 'Today'
                                                : 'Tomorrow';
                                      });
                                    },
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? nec.surface
                                            : nec.separator
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: nec.separator
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedDate,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: nec.textPrimary,
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.calendar,
                                            size: 16,
                                            color: nec.textTertiary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTime =
                                            _selectedTime == '11:00 AM'
                                                ? '3:30 PM'
                                                : '11:00 AM';
                                      });
                                    },
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? nec.surface
                                            : nec.separator
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: nec.separator
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedTime,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: nec.textPrimary,
                                            ),
                                          ),
                                          Icon(
                                            CupertinoIcons.clock,
                                            size: 16,
                                            color: nec.textTertiary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? nec.surface
                                : nec.separator.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _locationController,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Location / Address...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: nec.textTertiary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Purpose',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? nec.surface
                                : nec.separator.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _purposeController,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Product demo, site meeting...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: nec.textTertiary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NecButton(
                  label: 'Schedule Visit',
                  onPressed: _submitVisit,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
