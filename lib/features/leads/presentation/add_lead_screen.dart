import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/demo_session.dart';
import '../data/lead_store.dart';
import '../domain/models/lead.dart';
import '../../../core/widgets/nec_toast.dart';
import 'widgets/add_lead_step1.dart';
import 'widgets/add_lead_step2.dart';
import 'widgets/add_lead_step3.dart';
import 'widgets/add_lead_step4.dart';
import 'widgets/add_lead_step5.dart';

class AddLeadScreen extends StatefulWidget {
  final String? leadId;

  const AddLeadScreen({
    super.key,
    this.leadId,
  });

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  int _currentStep = 0;

  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedBusinessType;

  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRole;
  bool _isWhatsAppSame = false;

  final _propertiesController = TextEditingController();
  final _roomsController = TextEditingController();
  String? _selectedHms;

  String? _selectedPlan;
  Set<String> _selectedServices = {};

  final _notesController = TextEditingController();
  String? _selectedSource;
  String? _selectedEmployeeId;
  Lead? _original;
  bool _saving = false;
  final _actor = DemoSession.instance.employeeId;
  String? _selectedPriority = 'Normal';
  String? _attachedFileName;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = DemoSession.instance.employeeId;
    _original =
        widget.leadId == null ? null : LeadStore.instance.byId(widget.leadId!);
    final lead = _original;
    if (lead != null) {
      _companyController.text = lead.company;
      _selectedBusinessType = lead.type;
      _locationController.text = lead.location;
      _contactNameController.text = lead.contactName ?? '';
      _selectedRole = lead.contactRole;
      _phoneController.text = lead.phone ?? '';
      _isWhatsAppSame = lead.isWhatsAppSame;
      _emailController.text = lead.email ?? '';
      _propertiesController.text = lead.totalProperties?.toString() ?? '';
      _roomsController.text = lead.totalRooms?.toString() ?? '';
      _selectedHms = lead.currentHms;
      _selectedPlan = lead.interestedPlan;
      _selectedServices = Set.of(lead.interestedServices);
      _selectedSource = lead.source;
      _selectedEmployeeId = lead.assignedEmployeeId;
      _selectedPriority = lead.priority;
      _notesController.text = lead.notes;
      _attachedFileName = lead.attachmentName;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _propertiesController.dispose();
    _roomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _submitLead() async {
    if (_saving) return;
    if (_companyController.text.trim().isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a business name',
        type: NecToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (!DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != _actor) {
        throw const FormatException('Sign in again before saving this lead.');
      }
      final employeeId = DemoSession.instance.isAdmin
          ? _selectedEmployeeId
          : _original?.assignedEmployeeId ?? DemoSession.instance.employeeId;
      final lead = Lead(
        id: _original?.id ?? 'lead_${DateTime.now().microsecondsSinceEpoch}',
        company: _companyController.text.trim(),
        type: _selectedBusinessType ?? 'Other',
        location: _locationController.text.trim(),
        status: _original?.status ?? 'New',
        priority: _selectedPriority ?? 'Normal',
        createdAt: _original?.createdAt ?? DateTime.now(),
        assignedEmployeeId: employeeId,
        contactName: _contactNameController.text.trim(),
        contactRole: _selectedRole,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        source: _selectedSource,
        currentHms: _selectedHms,
        totalProperties: int.tryParse(_propertiesController.text),
        totalRooms: int.tryParse(_roomsController.text),
        interestedPlan: _selectedPlan,
        interestedServices: _selectedServices.toList(),
        notes: _notesController.text.trim(),
        attachmentName: _attachedFileName,
        isWhatsAppSame: _isWhatsAppSame,
        nextAction: _original?.nextAction,
        nextActionNote: _original?.nextActionNote,
        websiteStatus: _original?.websiteStatus,
        scheduleNote: _original?.scheduleNote ?? 'New lead',
        scheduleGroup: _original?.scheduleGroup ?? 'TODAY',
        overdueSnapshot: _original?.overdueSnapshot,
      );
      await LeadStore.instance.save(lead);
      if (!mounted) return;
      NecToast.show(context,
          message: widget.leadId == null
              ? 'Lead created successfully'
              : 'Lead updated successfully');
      context.pop();
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message
                : 'Unable to save this lead. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEditMode = widget.leadId != null;
    if (isEditMode && _original == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Lead unavailable')),
          body: const Center(child: Text('This lead could not be found.')));
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
                onPressed: _saving ? null : _previousStep,
                child: Text(
                  _currentStep == 0 ? 'Cancel' : '< Back',
                  style: TextStyle(
                    color: nec.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isEditMode ? 'Edit Lead' : 'New Lead',
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
                onPressed: _saving
                    ? null
                    : (_currentStep == 4 ? _submitLead : _nextStep),
                child: Text(
                  _currentStep == 4 ? (isEditMode ? 'Save' : 'Create') : 'Next',
                  style: TextStyle(
                    color: nec.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index == _currentStep;
                  final isDone = index < _currentStep;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? nec.brand
                          : (isDone
                              ? nec.brand.withValues(alpha: 0.5)
                              : nec.textTertiary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Container(
                color: nec.separator.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentStep,
          children: [
            AddLeadStep1(
              companyController: _companyController,
              locationController: _locationController,
              selectedBusinessType: _selectedBusinessType,
              onBusinessTypeChanged: (val) {
                setState(() {
                  _selectedBusinessType = val;
                });
              },
              onNext: _nextStep,
            ),
            AddLeadStep2(
              contactNameController: _contactNameController,
              phoneController: _phoneController,
              emailController: _emailController,
              selectedRole: _selectedRole,
              isWhatsAppSame: _isWhatsAppSame,
              onRoleChanged: (val) {
                setState(() {
                  _selectedRole = val;
                });
              },
              onWhatsAppSameChanged: (val) {
                setState(() {
                  _isWhatsAppSame = val;
                });
              },
              onNext: _nextStep,
            ),
            AddLeadStep3(
              propertiesController: _propertiesController,
              roomsController: _roomsController,
              selectedHms: _selectedHms,
              onHmsChanged: (val) {
                setState(() {
                  _selectedHms = val;
                });
              },
              onNext: _nextStep,
            ),
            AddLeadStep4(
              selectedPlan: _selectedPlan,
              selectedServices: _selectedServices,
              onPlanChanged: (val) {
                setState(() {
                  _selectedPlan = val;
                });
              },
              onServicesChanged: (val) {
                setState(() {
                  _selectedServices = val;
                });
              },
              onNext: _nextStep,
            ),
            AddLeadStep5(
              notesController: _notesController,
              selectedSource: _selectedSource,
              selectedEmployeeId: DemoSession.instance.isAdmin
                  ? _selectedEmployeeId
                  : _original?.assignedEmployeeId ??
                      DemoSession.instance.employeeId,
              isSaving: _saving,
              selectedPriority: _selectedPriority,
              attachedFileName: _attachedFileName,
              onSourceChanged: (val) {
                setState(() {
                  _selectedSource = val;
                });
              },
              onEmployeeChanged: (val) {
                if (!DemoSession.instance.isAdmin) return;
                setState(() => _selectedEmployeeId = val);
              },
              onPriorityChanged: (val) {
                setState(() {
                  _selectedPriority = val;
                });
              },
              onAttachmentChanged: (val) {
                setState(() {
                  _attachedFileName = val;
                });
              },
              onSubmit: _submitLead,
            ),
          ],
        ),
      ),
    );
  }
}
