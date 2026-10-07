import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import 'add_lead_picker_sheet.dart';
import 'lead_assignee_picker.dart';
import '../../../team/data/employee_store.dart';

class AddLeadStep5 extends StatefulWidget {
  final TextEditingController notesController;
  final String? selectedSource;
  final String? selectedEmployeeId;
  final String? selectedPriority;
  final String? attachedFileName;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String?> onAttachmentChanged;
  final VoidCallback onSubmit;
  final bool isSaving;

  const AddLeadStep5({
    super.key,
    required this.notesController,
    required this.selectedSource,
    required this.selectedEmployeeId,
    required this.selectedPriority,
    required this.attachedFileName,
    required this.onSourceChanged,
    required this.onEmployeeChanged,
    required this.onPriorityChanged,
    required this.onAttachmentChanged,
    required this.onSubmit,
    this.isSaving = false,
  });

  @override
  State<AddLeadStep5> createState() => _AddLeadStep5State();
}

class _AddLeadStep5State extends State<AddLeadStep5> {
  void _openSourcePicker(BuildContext context) {
    final sources = [
      {'label': 'Facebook'},
      {'label': 'Website'},
      {'label': 'WhatsApp'},
      {'label': 'Phone'},
      {'label': 'Referral'},
      {'label': 'Field Visit'},
      {'label': 'Campaign'},
      {'label': 'Manual'},
      {'label': 'Custom'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Lead Source',
        options: sources,
        selectedValue: widget.selectedSource,
        onSelected: (val) => widget.onSourceChanged(val as String),
      ),
    );
  }

  Future<void> _openEmployeePicker(BuildContext context) async {
    if (!DemoSession.instance.isAdmin) return;
    final actor = DemoSession.instance.employeeId;
    final selected =
        await chooseLeadAssignee(context, widget.selectedEmployeeId);
    if (!mounted ||
        selected == null ||
        !DemoSession.instance.isAdmin ||
        DemoSession.instance.employeeId != actor) {
      return;
    }
    widget.onEmployeeChanged(selected.isEmpty ? null : selected);
  }

  void _openPriorityPicker(BuildContext context) {
    final priorities = [
      {'label': 'Low', 'subtitle': 'Not time-sensitive', 'emoji': '↓'},
      {'label': 'Normal', 'subtitle': 'Standard follow-up', 'emoji': '→'},
      {'label': 'High', 'subtitle': 'Needs prompt attention', 'emoji': '↑'},
      {'label': 'Urgent', 'subtitle': 'Act immediately', 'emoji': '↑↑'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddLeadPickerSheet(
        title: 'Priority',
        options: priorities,
        selectedValue: widget.selectedPriority,
        onSelected: (val) => widget.onPriorityChanged(val as String),
      ),
    );
  }

  void _pickAttachment() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Add Attachment'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx'],
                );
                if (result != null && result.files.isNotEmpty) {
                  widget.onAttachmentChanged(result.files.first.name);
                  if (mounted) {
                    NecToast.show(
                      context,
                      message: 'Attached ${result.files.first.name}',
                      type: NecToastType.success,
                    );
                  }
                }
              } catch (_) {
                widget.onAttachmentChanged('lead_contract_draft.pdf');
              }
            },
            child: const Text('Document / PDF'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  widget.onAttachmentChanged(image.name);
                }
              } catch (_) {
                widget.onAttachmentChanged('property_image.jpg');
              }
            },
            child: const Text('Photo Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'LEAD ASSIGNMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: nec.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openSourcePicker(context),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_2,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.selectedSource ?? 'How did this lead come in?',
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.selectedSource != null
                                ? nec.textPrimary
                                : nec.textTertiary,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Assigned Employee',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: DemoSession.instance.isAdmin
                      ? () => _openEmployeePicker(context)
                      : null,
                  child: Row(children: [
                    NecAvatar(
                      initials: EmployeeStore.instance
                              .byId(widget.selectedEmployeeId ?? '')
                              ?.avatarInitials ??
                          '??',
                      photoBase64: EmployeeStore.instance
                          .byId(widget.selectedEmployeeId ?? '')
                          ?.photoBase64,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      EmployeeStore.instance
                              .byId(widget.selectedEmployeeId ?? '')
                              ?.name ??
                          'Unassigned',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary),
                    )),
                    const SizedBox(width: 8),
                    Icon(
                        DemoSession.instance.isAdmin
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.lock_fill,
                        size: 16,
                        color: nec.textTertiary),
                  ]),
                ),
                if (!DemoSession.instance.isAdmin) ...[
                  const SizedBox(height: 6),
                  Text(
                      'Automatically assigned to you. Only an admin can reassign this lead.',
                      style: TextStyle(
                          fontSize: 12, color: nec.textTertiary, height: 1.4)),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Text(
                  'Priority',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openPriorityPicker(context),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.brandLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.selectedPriority ?? 'Normal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ADDITIONAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: nec.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: TextStyle(fontSize: 13, color: nec.textTertiary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.notesController,
                  maxLines: 4,
                  style: TextStyle(fontSize: 14, color: nec.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'Client requirements, context, special requests...',
                    hintStyle: TextStyle(color: nec.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: nec.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.paperclip,
                  color: nec.brand,
                  size: 18,
                ),
              ),
              title: Text(
                widget.attachedFileName ?? 'Add Attachment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.attachedFileName != null
                      ? nec.textPrimary
                      : nec.textPrimary,
                ),
              ),
              subtitle: Text(
                widget.attachedFileName != null
                    ? 'Attached file'
                    : 'Photo, document, or file',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                ),
              ),
              trailing: widget.attachedFileName != null
                  ? GestureDetector(
                      onTap: () {
                        widget.onAttachmentChanged(null);
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 18,
                        color: nec.textTertiary,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.add_circled,
                      size: 20,
                      color: nec.brand,
                    ),
              onTap: _pickAttachment,
            ),
          ),
          const SizedBox(height: 32),
          NecButton(
            label: 'Create Lead',
            onPressed: widget.isSaving ? null : widget.onSubmit,
            loading: widget.isSaving,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
