import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'lead_attachment_viewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/lead_store.dart';
import 'add_lead_note_sheet.dart';

class LeadMoreTab extends StatefulWidget {
  final String leadId;
  final List<dynamic> notes;
  final List<dynamic> attachments;
  final List<dynamic> activities;

  const LeadMoreTab({
    super.key,
    required this.leadId,
    this.notes = const [],
    this.attachments = const [],
    this.activities = const [],
  });

  @override
  State<LeadMoreTab> createState() => _LeadMoreTabState();
}

class _LeadMoreTabState extends State<LeadMoreTab> {
  bool _uploading = false;

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onAdd,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nec.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (onAdd != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: Text(
                '+ Add',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openAddNoteDialog() {
    showLeadNoteSheet(
      context,
      leadId: widget.leadId,
      title: 'Add Note',
      hintText: 'Enter note content...',
    );
  }

  Future<void> _pickAndUploadAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          NecToast.show(context,
              message: 'Could not read file data', type: NecToastType.error);
        }
        return;
      }

      setState(() => _uploading = true);
      await LeadStore.instance.uploadAttachment(
        widget.leadId,
        filename: file.name,
        bytes: file.bytes!,
      );
      if (mounted) {
        NecToast.show(context,
            message: 'Attachment "${file.name}" uploaded successfully',
            type: NecToastType.success);
      }
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Failed to upload attachment. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openAssignmentHistory() {
    final nec = Theme.of(context).extension<NecColors>()!;
    final history = widget.activities
        .whereType<Map>()
        .where((a) =>
            (a['event']?.toString() ?? '').toLowerCase().contains('assign'))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Assignment History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No assignment changes recorded yet.',
                          style: TextStyle(color: nec.textTertiary),
                        ),
                      ),
                    )
                  else
                    ...history.map((h) => ListTile(
                          leading: const Icon(CupertinoIcons.person_badge_plus,
                              size: 20),
                          title: Text(h['description']?.toString() ??
                              'Lead assignment changed'),
                          subtitle: Text(h['occurred_at']?.toString() ?? ''),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStatusHistory() {
    final nec = Theme.of(context).extension<NecColors>()!;
    final history = widget.activities.whereType<Map>().where((a) {
      final ev = (a['event']?.toString() ?? '').toLowerCase();
      return ev.contains('update') ||
          ev.contains('status') ||
          ev.contains('create');
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Status & Lifecycle History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No status changes recorded yet.',
                          style: TextStyle(color: nec.textTertiary),
                        ),
                      ),
                    )
                  else
                    ...history.map((h) => ListTile(
                          leading: const Icon(CupertinoIcons.arrow_2_circlepath,
                              size: 20),
                          title: Text(
                              h['description']?.toString() ?? 'Status updated'),
                          subtitle: Text(h['occurred_at']?.toString() ?? ''),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Lead'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'The CRM backend does not allow deleting lead records permanently (API 405 Method Not Allowed).\n\nWould you like to mark this lead as "Lost" or "Cancelled" instead?',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Lead'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await LeadStore.instance.updateStatus(widget.leadId, 'Lost');
              if (mounted) {
                context.pop();
                NecToast.show(context,
                    message: 'Lead marked as Lost', type: NecToastType.info);
              }
            },
            child: const Text('Mark as Lost'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final notes = widget.notes.whereType<Map>().toList();
    final attachments = widget.attachments.whereType<Map>().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'NOTES',
            onAdd: _openAddNoteDialog,
          ),
          if (notes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No notes yet. Tap "+ Add" to write a note.',
                style: TextStyle(fontSize: 14, color: nec.textTertiary),
              ),
            )
          else
            ...notes.map((note) {
              final body = note['body']?.toString() ?? '';
              final authorMap =
                  note['author'] is Map ? note['author'] as Map : null;
              final authorName =
                  authorMap?['name']?.toString() ?? 'Team Member';
              final authorId = authorMap?['id']?.toString();
              final employee = authorId != null
                  ? EmployeeStore.instance.byId(authorId)
                  : null;
              final initials =
                  employee?.avatarInitials ?? Employee.initialsFor(authorName);
              final photoUrl = authorMap?['avatar_url']?.toString() ??
                  authorMap?['photo_url']?.toString() ??
                  authorMap?['avatar']?.toString();
              final photoBase64 = employee?.photoBase64;
              final time = note['created_at']?.toString() ?? '';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
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
                        NecAvatar(
                          initials: initials,
                          size: 34,
                          photoUrl: photoUrl,
                          photoBase64: photoBase64,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: nec.textPrimary,
                                ),
                              ),
                              if (time.isNotEmpty)
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: nec.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        color: nec.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );
            }),
          _buildSectionHeader(
            context,
            'ATTACHMENTS',
            onAdd: _uploading ? null : _pickAndUploadAttachment,
          ),
          if (_uploading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('Uploading attachment...',
                      style: TextStyle(color: nec.brand, fontSize: 13)),
                ],
              ),
            ),
          if (attachments.isEmpty && !_uploading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No attachments yet. Tap "+ Add" to upload documents.',
                style: TextStyle(fontSize: 14, color: nec.textTertiary),
              ),
            )
          else
            Material(
              color: nec.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(attachments.length, (index) {
                  final att = attachments[index];
                  final isLast = index == attachments.length - 1;
                  final name = att['name']?.toString() ?? 'Document';
                  final bytes = int.tryParse(att['size']?.toString() ?? '');
                  final size = bytes == null
                      ? ''
                      : bytes >= 1048576
                          ? '${(bytes / 1048576).toStringAsFixed(1)} MB'
                          : '${(bytes / 1024).toStringAsFixed(1)} KB';
                  final attachmentId = att['id']?.toString();
                  void view() {
                    if (attachmentId == null) return;
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => LeadAttachmentViewer(
                            leadId: widget.leadId,
                            attachmentId: attachmentId,
                            filename: name,
                            mimeType: att['mime_type']?.toString() ?? '')));
                  }

                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(CupertinoIcons.doc_fill,
                              color: AppColors.error, size: 20),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        subtitle: size.isNotEmpty
                            ? Text(size,
                                style: TextStyle(
                                    fontSize: 12, color: nec.textTertiary))
                            : null,
                        trailing: TextButton(
                            onPressed: attachmentId == null ? null : view,
                            child: const Text('View')),
                        onTap: attachmentId == null ? null : view,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                          indent: 56,
                        ),
                    ],
                  );
                }),
              ),
            ),
          _buildSectionHeader(context, 'ACTIONS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nec.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(CupertinoIcons.pencil, size: 16, color: nec.brand),
                  ),
                  title: Text('Edit Lead',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary)),
                  trailing: Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                  onTap: () => context.push('/edit-lead/${widget.leadId}'),
                ),
                Divider(
                    height: 1,
                    color: nec.separator.withValues(alpha: 0.2),
                    indent: 56),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.person_2,
                        size: 16, color: Color(0xFF7C3AED)),
                  ),
                  title: Text('Assignment History',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary)),
                  trailing: Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                  onTap: _openAssignmentHistory,
                ),
                Divider(
                    height: 1,
                    color: nec.separator.withValues(alpha: 0.2),
                    indent: 56),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.arrow_2_circlepath,
                        size: 16, color: Color(0xFF0284C7)),
                  ),
                  title: Text('Status History',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary)),
                  trailing: Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                  onTap: _openStatusHistory,
                ),
                Divider(
                    height: 1,
                    color: nec.separator.withValues(alpha: 0.2),
                    indent: 56),
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.trash,
                        size: 16, color: AppColors.error),
                  ),
                  title: const Text('Delete Lead',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error)),
                  trailing: Icon(CupertinoIcons.chevron_right,
                      size: 16, color: nec.textTertiary),
                  onTap: _confirmDelete,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
