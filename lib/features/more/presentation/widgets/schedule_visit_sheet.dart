import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../leads/data/lead_store.dart';
import '../../../leads/presentation/widgets/lead_location_map_picker.dart';
import '../../../tasks/data/work_item_store.dart';
import '../../../tasks/presentation/widgets/task_assign_sheet.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/work_queue_mapper.dart';
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
  bool _saving = false;
  late String _selectedLead;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTimeOfDay = const TimeOfDay(hour: 11, minute: 0);

  final _locationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  double? _latitude;
  double? _longitude;

  String _selectedPurposePreset = 'Client Meeting';
  final List<String> _purposePresets = [
    'Client Meeting',
    'Product Demo',
    'Site Inspection',
    'Contract Signing',
    'Payment Collection',
  ];

  String? _selectedAssigneeName;
  String? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    _selectedLead = widget.initialLeadName ?? '';
    _initAssignee();
    if (_selectedLead.isNotEmpty) {
      _applyLeadData(_selectedLead);
    }
  }

  void _initAssignee() {
    final currentEmp = EmployeeStore.instance.currentEmployee;
    _selectedAssigneeName = currentEmp.name;
    _selectedAssigneeId = currentEmp.backendId;
  }

  void _applyLeadData(String companyName) {
    final lead = LeadStore.instance.leads
        .where((l) => l.company == companyName)
        .firstOrNull;
    if (lead != null) {
      if (lead.location.isNotEmpty) {
        _locationController.text = lead.location;
      }
      _latitude = lead.latitude;
      _longitude = lead.longitude;
      if (lead.contactName != null && lead.contactName!.isNotEmpty) {
        _contactPersonController.text = lead.contactName!;
      }
      if (lead.phone != null && lead.phone!.isNotEmpty) {
        _contactPhoneController.text = lead.phone!;
      }
      if (DemoSession.instance.isAdmin &&
          lead.assignedTo != null &&
          lead.assignedTo!.isNotEmpty) {
        _selectedAssigneeName = lead.assignedTo;
        _selectedAssigneeId = lead.assignedEmployeeId;
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _purposeController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await LeadLocationMapPicker.show(
      context,
      initialLocation: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
    );
    if (result != null) {
      setState(() {
        _locationController.text = result.locationName;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
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
        _applyLeadData(lead);
      });
    }
  }

  void _openAssigneePicker() {
    if (!DemoSession.instance.isAdmin) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskAssignSheet(
        selectedAssignee: _selectedAssigneeName ?? 'None',
        onSelected: (val) {
          final emp = EmployeeStore.instance.employees
              .where((e) => e.name == val)
              .firstOrNull;
          setState(() {
            _selectedAssigneeName = val;
            _selectedAssigneeId = emp?.backendId;
          });
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(now) ? now : _selectedDateTime,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTimeOfDay.hour,
          _selectedTimeOfDay.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay,
    );
    if (picked != null) {
      setState(() {
        _selectedTimeOfDay = picked;
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _submitVisit() async {
    if (_saving) return;
    final lead = LeadStore.instance.leads
        .where((l) => l.company == _selectedLead)
        .firstOrNull;
    if (lead == null) {
      NecToast.show(
        context,
        message: 'Please select a lead before scheduling.',
        type: NecToastType.error,
      );
      return;
    }

    final customPurpose = _purposeController.text.trim();
    final purpose =
        customPurpose.isNotEmpty ? customPurpose : _selectedPurposePreset;
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : lead.location;
    final contactPerson = _contactPersonController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    final scheduled = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      _selectedTimeOfDay.hour,
      _selectedTimeOfDay.minute,
    );

    final isAdmin = DemoSession.instance.isAdmin;
    final currentEmp = EmployeeStore.instance.currentEmployee;

    final int? assigneeEmpId = isAdmin
        ? (_selectedAssigneeId != null
            ? int.tryParse(_selectedAssigneeId!.replaceFirst('api_emp_', ''))
            : (lead.assignedEmployeeId != null
                ? int.tryParse(
                    lead.assignedEmployeeId!.replaceFirst('api_emp_', ''))
                : int.tryParse(currentEmp.backendId ?? '')))
        : int.tryParse(currentEmp.backendId ?? '');

    setState(() => _saving = true);
    try {
      final saved = await WorkItemStore.instance.create({
        'type': 'visit',
        'title': purpose,
        'purpose': purpose,
        'visit_date': DateFormat('yyyy-MM-dd').format(scheduled),
        'visit_time': DateFormat('HH:mm').format(scheduled),
        'location': location,
        'details': {
          'purpose': purpose,
          'location': location,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
          if (contactPerson.isNotEmpty || contactPhone.isNotEmpty)
            'contact_person': {
              'name': contactPerson,
              'phone': contactPhone,
            },
        },
        'contact_person': {
          'name': contactPerson,
          'phone': contactPhone,
        },
        'lead_id': int.tryParse(lead.id) ?? lead.id,
        if (assigneeEmpId != null) 'assignee_employee_id': assigneeEmpId,
        'priority': 'medium',
        'scheduled_at': scheduled.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context, WorkQueueMapper.visit(saved));
      NecToast.show(
        context,
        message: 'Visit scheduled successfully',
        type: NecToastType.success,
      );
    } catch (error) {
      if (mounted) {
        NecToast.show(
          context,
          message: WorkItemStore.messageFor(error),
          type: NecToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);

    if (target == today) return 'Today';
    if (target == tomorrow) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(dt);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = DemoSession.instance.isAdmin;
    final currentEmp = EmployeeStore.instance.currentEmployee;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TARGET CLIENT / LEAD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _openLeadPicker,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedLead.isEmpty
                                    ? nec.separator.withValues(alpha: 0.25)
                                    : AppColors.brandLight
                                        .withValues(alpha: 0.4),
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
                                        .withValues(alpha: 0.12),
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
                                        _selectedLead.isEmpty
                                            ? 'Select a Lead'
                                            : _selectedLead,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedLead.isEmpty
                                              ? nec.textTertiary
                                              : nec.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedLead.isEmpty
                                            ? 'Tap to select client from leads'
                                            : 'Linked Lead · Tap to change',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandSubtleLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedLead.isEmpty ? 'Select' : 'Change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: nec.brand,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'CONDUCTED BY (REPRESENTATIVE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: isAdmin ? _openAssigneePicker : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: nec.separator.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                NecAvatar(
                                  initials: Employee.initialsFor(
                                      _selectedAssigneeName ?? currentEmp.name),
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedAssigneeName ??
                                            currentEmp.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: nec.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        isAdmin
                                            ? 'Assigned Representative'
                                            : 'Conducted by You',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: nec.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin)
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 14,
                                    color: nec.textTertiary,
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'SCHEDULED TIMING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: nec.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          nec.separator.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.calendar,
                                        size: 16,
                                        color: AppColors.brandLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatDate(_selectedDateTime),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: nec.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          nec.separator.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.clock,
                                        size: 16,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatTime(_selectedTimeOfDay),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: nec.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'PURPOSE OF VISIT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _purposePresets.map((preset) {
                            final isSel = _selectedPurposePreset == preset &&
                                _purposeController.text.trim().isEmpty;
                            return ChoiceChip(
                              label: Text(preset),
                              selected: isSel,
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPurposePreset = preset;
                                    _purposeController.clear();
                                  });
                                }
                              },
                              selectedColor: AppColors.brandLight,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : nec.textPrimary,
                              ),
                              backgroundColor: nec.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSel
                                      ? AppColors.brandLight
                                      : nec.separator.withValues(alpha: 0.25),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
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
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 2,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textPrimary,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Custom purpose or specific agenda notes...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: nec.textTertiary,
                                height: 1.35,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VISIT LOCATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: nec.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openMapPicker,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_circle_fill,
                                    size: 14,
                                    color: nec.brand,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pick on Map',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: nec.brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? nec.surface
                                : nec.separator.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _locationController,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter street, building, or address...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: nec.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 24,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 8),
                                child: Icon(
                                  CupertinoIcons.placemark_fill,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: nec.brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.checkmark_circle_fill,
                                    size: 13, color: nec.brand),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS Pin: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: nec.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // 6. CONTACT AT SITE
                        Text(
                          'SITE CONTACT PERSON',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: nec.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? nec.surface
                                      : nec.separator.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: nec.separator.withValues(alpha: 0.2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: _contactPersonController,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: nec.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Contact Name',
                                    hintStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: nec.textTertiary,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 24,
                                    ),
                                    prefixIcon: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 10, right: 6),
                                      child: Icon(
                                        CupertinoIcons.person_fill,
                                        size: 15,
                                        color: AppColors.brandLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? nec.surface
                                      : nec.separator.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: nec.separator.withValues(alpha: 0.2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: _contactPhoneController,
                                  keyboardType: TextInputType.phone,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: nec.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: nec.textTertiary,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 24,
                                    ),
                                    prefixIcon: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 10, right: 6),
                                      child: Icon(
                                        CupertinoIcons.phone_fill,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: NecButton(
                    label: _saving ? 'Scheduling...' : 'Schedule Visit',
                    loading: _saving,
                    onPressed: _saving ? null : _submitVisit,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
