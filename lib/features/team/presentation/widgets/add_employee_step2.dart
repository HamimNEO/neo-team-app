import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/employee_store.dart';
import '../../data/department_store.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../auth/presentation/widgets/auth_field.dart';
import 'add_employee_picker_sheet.dart';
import 'agreement_pdf_viewer.dart';

class AddEmployeeStep2 extends StatelessWidget {
  final TextEditingController employeeIdController;
  final TextEditingController designationController;
  final TextEditingController joiningDateController;
  final String? selectedDepartment, selectedDepartmentId;
  final String? selectedTeam;
  final String? selectedManager;
  final String? selectedManagerId;
  final ValueChanged<String?>? onManagerIdChanged;
  final String selectedStatus;
  final ValueChanged<String> onDepartmentChanged;
  final ValueChanged<String> onTeamChanged;
  final ValueChanged<String> onManagerChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onContinue;
  final ValueChanged<String?>? onDepartmentIdChanged;
  final String? editingEmployeeId;

  // Extra Probation & Agreement fields
  final String employmentType; // 'permanent' or 'probation'
  final ValueChanged<String> onEmploymentTypeChanged;
  final TextEditingController probationStartDateController;
  final TextEditingController probationEndDateController;
  final String? agreementPdfName;
  final String? agreementPdfBase64;
  final int? agreementPdfSizeBytes;
  final void Function({
    required String fileName,
    required String base64Data,
    required int sizeBytes,
  })? onAgreementPdfPicked;
  final VoidCallback? onAgreementPdfRemoved;

  const AddEmployeeStep2({
    super.key,
    required this.employeeIdController,
    required this.designationController,
    required this.joiningDateController,
    required this.selectedDepartment,
    this.selectedDepartmentId,
    this.onDepartmentIdChanged,
    required this.selectedTeam,
    required this.selectedManager,
    this.selectedManagerId,
    this.onManagerIdChanged,
    required this.selectedStatus,
    required this.onDepartmentChanged,
    required this.onTeamChanged,
    required this.onManagerChanged,
    required this.onStatusChanged,
    required this.onContinue,
    this.editingEmployeeId,
    required this.employmentType,
    required this.onEmploymentTypeChanged,
    required this.probationStartDateController,
    required this.probationEndDateController,
    this.agreementPdfName,
    this.agreementPdfBase64,
    this.agreementPdfSizeBytes,
    this.onAgreementPdfPicked,
    this.onAgreementPdfRemoved,
  });

  Future<void> _showDepartmentPicker(BuildContext context) async {
    final store = DepartmentStore.instance;
    await store.load();
    if (!context.mounted) return;
    if (store.error != null && !store.hasData) {
      NecToast.show(context, message: store.error!, type: NecToastType.error);
      return;
    }
    if (!store.departments.any((d) => d.isActive == true)) {
      NecToast.show(context,
          message: 'No active departments available.', type: NecToastType.info);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Select Department',
        selectedValue: selectedDepartmentId,
        options: store.departments
            .where((d) => d.isActive == true)
            .map((d) =>
                PickerOption(title: d.name, subtitle: d.code, value: d.id))
            .toList(),
        onSelected: (opt) {
          onDepartmentChanged(opt.title);
          onDepartmentIdChanged?.call(opt.value);
        },
      ),
    );
  }

  Future<void> _showTeamPicker(BuildContext context) async {
    final store = EmployeeStore.instance;
    await store.load();
    if (!context.mounted) return;
    final names = store.employees
        .where((employee) =>
            employee.departmentId == selectedDepartmentId &&
            employee.team.isNotEmpty)
        .map((employee) => employee.team)
        .toSet()
        .toList()
      ..sort();
    final controller = TextEditingController(text: selectedTeam);
    final route = DialogRoute<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Select Team'),
              content: SizedBox(
                width: double.maxFinite,
                child: names.isEmpty
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                            labelText: 'Team Name',
                            hintText: 'Enter team name'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          ...names.map((name) => ListTile(
                                title: Text(name),
                                trailing: name == selectedTeam
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : null,
                                onTap: () => Navigator.of(ctx).pop(name),
                              )),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Add new team...'),
                            onTap: () async {
                              final text = await showDialog<String>(
                                  context: ctx,
                                  builder: (c) {
                                    final addController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: const Text('New Team'),
                                      content: TextField(
                                        controller: addController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Team Name'),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(c).pop(),
                                            child: const Text('Cancel')),
                                        FilledButton(
                                            onPressed: () => Navigator.of(c)
                                                .pop(addController.text.trim()),
                                            child: const Text('Save')),
                                      ],
                                    );
                                  });
                              if (ctx.mounted &&
                                  text != null &&
                                  text.isNotEmpty) {
                                Navigator.of(ctx).pop(text);
                              }
                            },
                          )
                        ],
                      ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                if (names.isEmpty)
                  FilledButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(controller.text.trim()),
                      child: const Text('Save')),
              ],
            ));
    final team = await Navigator.of(context).push(route);
    if (team != null && team.isNotEmpty) {
      onTeamChanged(team);
    }
  }

  void _showManagerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Select Reporting Manager',
        selectedValue: selectedManagerId ?? selectedManager,
        options: [
          const PickerOption(title: 'Not assigned', value: ''),
          ...EmployeeStore.instance.employees
              .where((employee) =>
                  employee.status == 'Active' &&
                  employee.id != editingEmployeeId &&
                  employee.backendId != null)
              .map((employee) => PickerOption(
                  title: employee.name,
                  value: employee.id,
                  subtitle:
                      '${employee.designation} · ${employee.displayCode}')),
        ],
        onSelected: (opt) {
          onManagerChanged(opt.title);
          onManagerIdChanged?.call(opt.value);
        },
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddEmployeePickerSheet(
        title: 'Employment Status',
        selectedValue: selectedStatus,
        options: const [
          PickerOption(title: 'Active'),
          PickerOption(title: 'Inactive'),
        ],
        onSelected: (opt) => onStatusChanged(opt.title),
      ),
    );
  }

  Future<void> _pickAgreementPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final name = file.name;
        final bytes = file.bytes;
        final size = file.size;
        if (bytes != null) {
          final base64String = base64Encode(bytes);
          onAgreementPdfPicked?.call(
            fileName: name,
            base64Data: base64String,
            sizeBytes: size,
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Could not access file. Please try again.',
          type: NecToastType.error,
        );
      }
    }
  }

  void _previewAgreementPdf(BuildContext context) {
    if (agreementPdfBase64 == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgreementPdfViewer(
          title: agreementPdfName ?? 'Employment Agreement',
          base64Data: agreementPdfBase64,
        ),
      ),
    );
  }

  void _applyProbationPreset(int months) {
    final start = DateTime.tryParse(probationStartDateController.text) ??
        DateTime.tryParse(joiningDateController.text) ??
        DateTime.now();
    probationStartDateController.text =
        start.toIso8601String().substring(0, 10);
    final end = DateTime(start.year, start.month + months, start.day);
    probationEndDateController.text = end.toIso8601String().substring(0, 10);
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String valueText,
    required VoidCallback onTap,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: nec.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: nec.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: nec.separator, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                  valueText,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueText.startsWith('Select')
                        ? nec.textTertiary
                        : nec.textPrimary,
                  ),
                )),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: nec.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isValid = designationController.text.trim().isNotEmpty;
    final isProbation = employmentType.toLowerCase() == 'probation';

    // Calculate duration days if both start and end dates are present
    int? probationDays;
    final pStart = DateTime.tryParse(probationStartDateController.text);
    final pEnd = DateTime.tryParse(probationEndDateController.text);
    if (pStart != null && pEnd != null && !pEnd.isBefore(pStart)) {
      probationDays = pEnd.difference(pStart).inDays;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthField(
            label: 'Employee ID *',
            hintText: 'e.g. NEC-EMP-008',
            controller: employeeIdController,
            readOnly: editingEmployeeId != null,
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'Designation *',
            hintText: 'e.g. Sales Executive',
            controller: designationController,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Department *',
            valueText: selectedDepartment ?? 'Select department',
            onTap: () => _showDepartmentPicker(context),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Team *',
            valueText: selectedTeam ?? 'Select team',
            onTap: () => _showTeamPicker(context),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Reporting Manager',
            valueText: selectedManager ?? 'Select manager',
            onTap: () => _showManagerPicker(context),
          ),
          const SizedBox(height: 16),
          AuthField(
            label: 'Joining Date *',
            hintText: 'Select joining date',
            controller: joiningDateController,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(joiningDateController.text) ??
                      DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100));
              if (context.mounted && date != null) {
                joiningDateController.text =
                    date.toIso8601String().substring(0, 10);
                if (probationStartDateController.text.isEmpty) {
                  probationStartDateController.text =
                      joiningDateController.text;
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            context: context,
            label: 'Employment Status',
            valueText: selectedStatus,
            onTap: () => _showStatusPicker(context),
          ),

          const SizedBox(height: 24),
          // ─── EMPLOYMENT TYPE (Permanent vs Probation) ───────────────
          Text(
            'Employment Type *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EmploymentTypeCard(
                  title: 'Permanent',
                  subtitle: 'Confirmed employee',
                  icon: CupertinoIcons.checkmark_shield_fill,
                  isSelected: !isProbation,
                  selectedColor: const Color(0xFF10B981),
                  onTap: () => onEmploymentTypeChanged('permanent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EmploymentTypeCard(
                  title: 'Probation',
                  subtitle: 'Trial period tracking',
                  icon: CupertinoIcons.timer,
                  isSelected: isProbation,
                  selectedColor: const Color(0xFFF59E0B),
                  onTap: () {
                    onEmploymentTypeChanged('probation');
                    if (probationStartDateController.text.isEmpty) {
                      probationStartDateController.text =
                          joiningDateController.text.isNotEmpty
                              ? joiningDateController.text
                              : DateTime.now().toIso8601String().substring(0, 10);
                    }
                    if (probationEndDateController.text.isEmpty) {
                      _applyProbationPreset(3);
                    }
                  },
                ),
              ),
            ],
          ),

          // ─── PROBATION PERIOD SECTION ─────────────────────────────
          if (isProbation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.timer,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Probation Period Schedule',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Presets Row
                  Row(
                    children: [
                      Text(
                        'Quick presets:',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PresetChip(
                        label: '3 Mo',
                        onTap: () => _applyProbationPreset(3),
                      ),
                      const SizedBox(width: 6),
                      _PresetChip(
                        label: '6 Mo',
                        onTap: () => _applyProbationPreset(6),
                      ),
                      const SizedBox(width: 6),
                      _PresetChip(
                        label: '1 Yr',
                        onTap: () => _applyProbationPreset(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date Fields Row
                  Row(
                    children: [
                      Expanded(
                        child: AuthField(
                          label: 'Start Date *',
                          hintText: 'Start date',
                          controller: probationStartDateController,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(
                                      probationStartDateController.text) ??
                                  DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (context.mounted && date != null) {
                              probationStartDateController.text =
                                  date.toIso8601String().substring(0, 10);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthField(
                          label: 'End Date *',
                          hintText: 'End date',
                          controller: probationEndDateController,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(
                                      probationEndDateController.text) ??
                                  DateTime.now().add(const Duration(days: 90)),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2100),
                            );
                            if (context.mounted && date != null) {
                              probationEndDateController.text =
                                  date.toIso8601String().substring(0, 10);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (probationDays != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Text(
                            'Duration: $probationDays days · Alert at period end',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          // ─── EMPLOYMENT AGREEMENT PDF (Optional) ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employment Agreement (PDF)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: nec.separator.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: nec.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (agreementPdfName != null && agreementPdfName!.isNotEmpty)
            // Attached File Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: nec.brand.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.doc_fill,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agreementPdfName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFileSize(agreementPdfSizeBytes),
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.eye, size: 20),
                    color: nec.brand,
                    tooltip: 'Preview PDF',
                    onPressed: () => _previewAgreementPdf(context),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash, size: 18),
                    color: const Color(0xFFEF4444),
                    tooltip: 'Remove',
                    onPressed: onAgreementPdfRemoved,
                  ),
                ],
              ),
            )
          else
            // Empty Upload Button
            InkWell(
              onTap: () => _pickAgreementPdf(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: nec.brand.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.arrow_up_doc,
                        size: 20,
                        color: nec.brand,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attach Agreement Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: nec.brand,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'PDF format supported',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
          NecButton(
            label: 'Continue',
            onPressed: isValid ? onContinue : null,
            fullWidth: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EmploymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _EmploymentTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.08) : nec.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : nec.separator,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? selectedColor : nec.textTertiary,
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: selectedColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? selectedColor : nec.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: nec.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
      ),
    );
  }
}
