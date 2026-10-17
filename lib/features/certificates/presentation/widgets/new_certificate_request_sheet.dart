import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import '../../data/certificate_store.dart';
import '../../domain/models/certificate_request.dart';

class NewCertificateRequestSheet extends StatefulWidget {
  final String? employeeId;

  const NewCertificateRequestSheet({super.key, this.employeeId});

  static Future<bool?> show(BuildContext context, {String? employeeId}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewCertificateRequestSheet(employeeId: employeeId),
    );
  }

  @override
  State<NewCertificateRequestSheet> createState() =>
      _NewCertificateRequestSheetState();
}

class _NewCertificateRequestSheetState
    extends State<NewCertificateRequestSheet> {
  CertificateType _selectedType = CertificateType.workExperience;
  String _selectedPurpose = 'New Employment';
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;

  final List<String> _purposeOptions = [
    'New Employment',
    'Higher Education & Admissions',
    'Visa & Immigration',
    'Bank & Financial Verification',
    'General Career Record',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final empId = widget.employeeId ?? DemoSession.instance.employeeId;
    final emp = EmployeeStore.instance.byId(empId) ??
        EmployeeStore.instance.employees.first;

    setState(() => _submitting = true);

    try {
      await CertificateStore.instance.submitRequest(
        employeeId: emp.id,
        employeeName: emp.name,
        employeeCode: emp.displayCode,
        employeeDesignation: emp.designation,
        employeeDepartment: emp.department,
        joinedDate: emp.joinedDate,
        type: _selectedType,
        purpose: _selectedPurpose,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      NecToast.show(
        context,
        message: 'Certificate request submitted to administration!',
        type: NecToastType.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        NecToast.show(
          context,
          message: 'Failed to submit request: $e',
          type: NecToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Certificate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: nec.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 18),
                      color: nec.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  'Select the document type you need from NEONECY administration.',
                  style: TextStyle(fontSize: 13, color: nec.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOCUMENT TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: nec.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...CertificateType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? nec.brand.withValues(alpha: 0.08)
                              : nec.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? nec.brand : nec.separator,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: isSelected ? nec.brand : nec.textTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? nec.brand
                                          : nec.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.subtitle,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: nec.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    'PURPOSE OF REQUEST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: nec.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: nec.separator),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPurpose,
                        isExpanded: true,
                        icon: Icon(CupertinoIcons.chevron_down,
                            size: 14, color: nec.textSecondary),
                        items: _purposeOptions.map((purpose) {
                          return DropdownMenuItem<String>(
                            value: purpose,
                            child: Text(
                              purpose,
                              style: TextStyle(
                                  fontSize: 14, color: nec.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPurpose = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SPECIAL REMARKS OR NOTES (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: nec.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: nec.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Please highlight my contributions on lead CRM architecture, or if required by a specific deadline.',
                      hintStyle:
                          TextStyle(fontSize: 13, color: nec.textTertiary),
                      filled: true,
                      fillColor: nec.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: nec.brand, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: nec.surface,
              border: Border(
                top: BorderSide(color: nec.separator.withValues(alpha: 0.4)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nec.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Submit Request to Administration',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
