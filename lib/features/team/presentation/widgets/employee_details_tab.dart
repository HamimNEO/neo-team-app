import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/storage/file_export.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/department_store.dart';
import '../../data/employee_store.dart';
import '../../data/team_store.dart';
import '../../domain/models/employee.dart';
import 'add_employee_picker_sheet.dart';
import 'agreement_pdf_viewer.dart';
import 'employee_details_section.dart';

class EmployeeDetailsTab extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailsTab({super.key, required this.employee});

  Future<void> _pickDepartment(BuildContext context) async {
    final deptStore = DepartmentStore.instance;
    await deptStore.load();
    if (!context.mounted) return;

    final options = deptStore.departments
        .where((d) => d.isActive != false)
        .map((d) => PickerOption(
              title: d.name,
              subtitle: d.code != null ? 'Code: ${d.code}' : null,
              value: d.id,
            ))
        .toList();

    if (options.isEmpty) {
      NecToast.show(
        context,
        message: 'No active departments available',
        type: NecToastType.info,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddEmployeePickerSheet(
        title: 'Select Department',
        selectedValue: employee.departmentId ?? employee.department,
        options: options,
        onSelected: (selected) async {
          if (selected.value == null) return;
          try {
            NecToast.show(
              context,
              message: 'Updating department...',
              type: NecToastType.info,
            );
            await EmployeeStore.instance.assignDepartment(
              employee,
              selected.value!,
              selected.title,
            );
            if (context.mounted) {
              NecToast.show(
                context,
                message: 'Department updated to ${selected.title}',
                type: NecToastType.success,
              );
            }
          } catch (e) {
            if (context.mounted) {
              NecToast.show(
                context,
                message: EmployeeStore.messageFor(e),
                type: NecToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _pickTeam(BuildContext context) async {
    final teamStore = TeamStore.instance;
    await teamStore.load();
    if (!context.mounted) return;

    final existingTeams = teamStore.teams.map((t) => t.name).toSet();
    if (employee.team.isNotEmpty) existingTeams.add(employee.team);

    final options = [
      ...existingTeams.map((name) => PickerOption(
            title: name,
            value: name,
          )),
      const PickerOption(
        title: '+ Enter Custom Team Name...',
        value: '__CUSTOM__',
      ),
    ];

    final team = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddEmployeePickerSheet(
        title: 'Select Team',
        selectedValue: employee.team,
        options: options,
        onSelected: (selected) async {
          if (selected.value == '__CUSTOM__') {
            final custom = await showDialog<String>(
              context: context,
              builder: (dCtx) {
                final c = TextEditingController();
                return AlertDialog(
                  title: const Text('New Team Name'),
                  content: TextField(
                    controller: c,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mobile Engineering',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(dCtx).pop(c.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
            if (custom != null && custom.isNotEmpty && context.mounted) {
              Navigator.of(ctx).pop(custom);
            }
          } else if (selected.value != null && context.mounted) {
            Navigator.of(ctx).pop(selected.value);
          }
        },
      ),
    );

    if (team != null && team.isNotEmpty && context.mounted) {
      try {
        NecToast.show(
          context,
          message: 'Updating team...',
          type: NecToastType.info,
        );
        await EmployeeStore.instance.assignTeam(employee, team);
        if (context.mounted) {
          NecToast.show(
            context,
            message: 'Team updated to $team',
            type: NecToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          NecToast.show(
            context,
            message: EmployeeStore.messageFor(e),
            type: NecToastType.error,
          );
        }
      }
    }
  }

  Future<void> _pickReportsTo(BuildContext context) async {
    final empStore = EmployeeStore.instance;
    await empStore.load();
    if (!context.mounted) return;

    final candidates = empStore.employees
        .where((e) =>
            e.id != employee.id &&
            e.status.toLowerCase() == 'active' &&
            e.backendId != null)
        .toList();

    final options = [
      const PickerOption(
        title: 'None (No reporting manager)',
        value: '__NONE__',
      ),
      ...candidates.map((c) => PickerOption(
            title: c.name,
            subtitle: '${c.designation} · ${c.displayCode}',
            value: c.id,
          )),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddEmployeePickerSheet(
        title: 'Select Reporting Manager',
        selectedValue: employee.reportsToId ?? '__NONE__',
        options: options,
        onSelected: (selected) async {
          final managerId =
              selected.value == '__NONE__' ? null : selected.value;
          final managerName =
              selected.value == '__NONE__' ? null : selected.title;
          try {
            NecToast.show(
              context,
              message: 'Updating manager...',
              type: NecToastType.info,
            );
            await EmployeeStore.instance.assignManager(
              employee,
              managerId,
              managerName,
            );
            if (context.mounted) {
              NecToast.show(
                context,
                message: managerName != null
                    ? 'Reports To updated to $managerName'
                    : 'Reporting manager removed',
                type: NecToastType.success,
              );
            }
          } catch (e) {
            if (context.mounted) {
              NecToast.show(
                context,
                message: EmployeeStore.messageFor(e),
                type: NecToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _pickSystemRole(BuildContext context) async {
    final options = [
      const PickerOption(
        title: 'Operations Manager',
        subtitle: 'Supervises leads, tasks, follow-ups, and field visits',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Sales Executive',
        subtitle: 'Handles sales leads, follow-ups, and customer outreach',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Flutter Developer',
        subtitle: 'Mobile engineering role focusing on tasks & issues',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Backend Developer',
        subtitle: 'Core backend engineering role with API & tasks',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Digital Marketing Specialist',
        subtitle: 'Manages marketing leads, campaigns, and tasks',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Customer Support Executive',
        subtitle: 'Handles issue tracking, feedback, and customer queries',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'General Manager',
        subtitle: 'Full operational team management',
        value: 'TEAM_OPERATIONS',
      ),
      const PickerOption(
        title: 'Super Admin',
        subtitle: 'Full system and administration access',
        value: 'SUPER_ADMIN',
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddEmployeePickerSheet(
        title: 'Select System Role',
        selectedValue: employee.systemRole,
        options: options,
        onSelected: (selected) async {
          try {
            NecToast.show(
              context,
              message: 'Updating role...',
              type: NecToastType.info,
            );
            await EmployeeStore.instance.assignRole(
              employee,
              selected.value ?? 'TEAM_OPERATIONS',
              selected.title,
            );
            if (context.mounted) {
              NecToast.show(
                context,
                message: 'System Role updated to ${selected.title}',
                type: NecToastType.success,
              );
            }
          } catch (e) {
            if (context.mounted) {
              NecToast.show(
                context,
                message: EmployeeStore.messageFor(e),
                type: NecToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmPromotePermanent(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Promote to Permanent'),
        content: Text(
          'Are you sure you want to promote ${employee.name} from Probation to Permanent employment status?',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Promote'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        NecToast.show(
          context,
          message: 'Updating status to Permanent...',
          type: NecToastType.info,
        );
        await EmployeeStore.instance.updateEmploymentType(
          employee,
          'permanent',
        );
        if (context.mounted) {
          NecToast.show(
            context,
            message: '${employee.name} promoted to Permanent status!',
            type: NecToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          NecToast.show(
            context,
            message: EmployeeStore.messageFor(e),
            type: NecToastType.error,
          );
        }
      }
    }
  }

  void _openAgreementViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgreementPdfViewer(
          title: employee.agreementPdfName ?? 'Employment Agreement',
          base64Data: employee.agreementPdfBase64,
          url: employee.agreementPdfUrl,
        ),
      ),
    );
  }

  Future<void> _saveAgreementPdf(BuildContext context) async {
    if (employee.agreementPdfBase64 == null) return;
    try {
      final clean = employee.agreementPdfBase64!.contains(',')
          ? employee.agreementPdfBase64!.split(',').last
          : employee.agreementPdfBase64!;
      final bytes = base64Decode(clean);
      final filename =
          employee.agreementPdfName ?? 'employment_agreement.pdf';
      await FileExport.save(filename, bytes);
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Agreement saved to your device',
          type: NecToastType.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Could not save agreement file.',
          type: NecToastType.error,
        );
      }
    }
  }

  Future<void> _pickAndAttachAgreement(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null && context.mounted) {
          final base64String = base64Encode(bytes);
          NecToast.show(
            context,
            message: 'Attaching agreement...',
            type: NecToastType.info,
          );
          await EmployeeStore.instance.attachAgreementPdf(
            employee,
            fileName: file.name,
            base64: base64String,
            sizeBytes: file.size,
          );
          if (context.mounted) {
            NecToast.show(
              context,
              message: 'Agreement PDF attached successfully',
              type: NecToastType.success,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Failed to attach agreement: ${EmployeeStore.messageFor(e)}',
          type: NecToastType.error,
        );
      }
    }
  }

  Widget _buildProbationProgressCard(
      BuildContext context, NecColors nec, bool isAdmin) {
    if (!employee.isProbation) return const SizedBox.shrink();

    final isCompleted = employee.isProbationCompleted;
    final progress = employee.probationProgress;
    final percent = (progress * 100).toInt();
    final remainingDays = employee.probationRemainingDays;
    final elapsedDays = employee.probationElapsedDays;
    final totalDays = employee.probationTotalDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? CupertinoIcons.checkmark_shield_fill
                          : CupertinoIcons.timer,
                      size: 16,
                      color: isCompleted
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Probation Period Progress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted
                      ? 'Completed'
                      : '$remainingDays days left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  color: nec.separator.withValues(alpha: 0.3),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.01, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [
                                const Color(0xFF10B981),
                                const Color(0xFF059669)
                              ]
                            : [
                                const Color(0xFFFBBF24),
                                const Color(0xFFF59E0B)
                              ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date & Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${employee.probationStartDate ?? employee.joinedDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percent% ($elapsedDays / $totalDays days)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),
              ),
              Text(
                'End: ${employee.probationEndDate ?? '—'}',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Status & Promotion Action
          if (isCompleted || remainingDays <= 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF059669), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAdmin
                          ? 'Probation period ended. You can now update status to Permanent.'
                          : 'Your probation period has concluded. Admin has been notified to review your permanent status.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon:
                      const Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
                  label: const Text(
                    'Promote to Permanent',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _confirmPromotePermanent(context),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAgreementCard(
      BuildContext context, NecColors nec, bool isAdmin) {
    final hasAgreement = employee.hasAgreementPdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nec.separator.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Employment Agreement',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                ],
              ),
              if (hasAgreement)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Attached PDF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAgreement) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nec.separator.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.doc_fill,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.agreementPdfName ??
                              'Employment_Agreement.pdf',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Official Signed Contract',
                          style: TextStyle(
                            fontSize: 11,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.eye, size: 20),
                    color: nec.brand,
                    tooltip: 'View Document',
                    onPressed: () => _openAgreementViewer(context),
                  ),
                  if (employee.agreementPdfBase64 != null)
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrow_down_doc, size: 19),
                      color: nec.brand,
                      tooltip: 'Download',
                      onPressed: () => _saveAgreementPdf(context),
                    ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nec.separator.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.doc_text,
                      size: 20, color: nec.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No agreement PDF attached yet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: nec.textTertiary,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _pickAndAttachAgreement(context),
                      icon: const Icon(CupertinoIcons.plus, size: 14),
                      label: const Text('Upload PDF',
                          style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isAdmin =
        DemoSession.instance.isAdmin || EmployeeStore.instance.canManage;

    final onRowTap = isAdmin
        ? {
            'System Role': () => _pickSystemRole(context),
            'Department': () => _pickDepartment(context),
            'Team': () => _pickTeam(context),
            'Reports To': () => _pickReportsTo(context),
          }
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ─── PROBATION PROGRESS (visible to both employee & admin) ───
          _buildProbationProgressCard(context, nec, isAdmin),

          // ─── AGREEMENT DOCUMENT (visible to both employee & admin) ───
          _buildAgreementCard(context, nec, isAdmin),

          EmployeeDetailsSection(
            title: 'Employment',
            rows: [
              ('Employee ID', employee.displayCode),
              ('Designation', employee.designation),
              (
                'Employment Type',
                employee.isProbation
                    ? 'Probation (${employee.probationRemainingDays} days left)'
                    : 'Permanent'
              ),
              if (employee.isProbation)
                (
                  'Probation Period',
                  '${employee.probationStartDate ?? employee.joinedDate} to ${employee.probationEndDate ?? '—'}'
                ),
              ('Status', employee.status),
              ('Joined', employee.joinedDate),
              ('System Role', employee.systemRole),
              ('Department', employee.department.split(' · ').first),
              ('Team', employee.team),
              (
                'Reports To',
                (employee.reportsTo != null &&
                        employee.reportsTo!.trim().isNotEmpty &&
                        employee.reportsTo!.toLowerCase() != 'null')
                    ? employee.reportsTo!
                    : (employee.reportsToId != null &&
                            EmployeeStore.instance
                                    .byId(employee.reportsToId!)
                                    ?.name !=
                                null)
                        ? EmployeeStore.instance
                            .byId(employee.reportsToId!)!
                            .name
                        : 'Not assigned'
              ),
            ],
            onRowTap: onRowTap,
          ),
          if (employee.benefitsKnown &&
              (employee.companyMealEnabled || employee.hasRotationalReserve))
            EmployeeDetailsSection(
              title: 'Benefits & Schemes',
              rows: [
                (
                  'Meal Policy',
                  !employee.companyMealEnabled
                      ? 'Not enrolled'
                      : employee.isMealFree
                          ? '100% Free (৳${(employee.totalMealCost / 100).toStringAsFixed(0)} / mo Sponsored)'
                          : '${employee.mealCoPayPercent}% Co-Pay (৳${(employee.mealEmployeePayAmount / 100).toStringAsFixed(0)} / mo Cut From Salary)'
                ),
                (
                  'Rotational Reserve',
                  employee.hasRotationalReserve
                      ? '৳${(employee.rotationalReserveAmount / 100).toStringAsFixed(0)} / month'
                      : 'Not enrolled'
                ),
              ],
            ),
          EmployeeDetailsSection(
            title: 'Contact',
            rows: [
              ('Work Email', employee.email),
              ('Phone', employee.phone),
              ('Address', employee.address),
            ],
          ),
          EmployeeDetailsSection(
            title: 'Personal information',
            rows: [
              ('Full Name', employee.name),
              ('Date of Birth', employee.dateOfBirth),
            ],
          ),
          EmployeeDetailsSection(
            title: 'Emergency contact',
            rows: [
              ('Name', employee.emergencyContactName),
              ('Phone', employee.emergencyContactPhone),
            ],
          ),
        ],
      ),
    );
  }
}
