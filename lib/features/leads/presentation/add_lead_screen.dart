import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
  String? _selectedEmployee = 'Shahina Akter';
  String? _selectedPriority = 'Normal';
  String? _attachedFileName;

  @override
  void initState() {
    super.initState();
    if (widget.leadId != null) {
      _companyController.text = 'Sea Pearl Resort';
      _selectedBusinessType = 'Resort';
      _locationController.text = "Cox's Bazar";

      _contactNameController.text = 'Abdul Karim';
      _selectedRole = 'General Manager';
      _phoneController.text = '+880 1711 234567';
      _isWhatsAppSame = true;
      _emailController.text = 'karim@seapearl.com';

      _propertiesController.text = '1';
      _roomsController.text = '120';
      _selectedHms = 'IDS Next';

      _selectedPlan = 'Enterprise';
      _selectedServices = {'Hotel Management', 'Hotel Website', 'Guest App'};

      _selectedSource = 'Referral';
      _selectedEmployee = 'Shahina Akter';
      _selectedPriority = 'Normal';
      _notesController.text =
          'Client requirements, context, special requests...';
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

  void _submitLead() {
    if (_companyController.text.trim().isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a business name',
        type: NecToastType.error,
      );
      return;
    }

    context.pop();
    NecToast.show(
      context,
      message: widget.leadId != null
          ? 'Lead updated successfully'
          : 'Lead created successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEditMode = widget.leadId != null;

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
                onPressed: _previousStep,
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
                onPressed: _currentStep == 4 ? _submitLead : _nextStep,
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
              selectedEmployee: _selectedEmployee,
              selectedPriority: _selectedPriority,
              attachedFileName: _attachedFileName,
              onSourceChanged: (val) {
                setState(() {
                  _selectedSource = val;
                });
              },
              onEmployeeChanged: (val) {
                setState(() {
                  _selectedEmployee = val;
                });
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
