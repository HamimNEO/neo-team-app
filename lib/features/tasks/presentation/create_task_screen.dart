import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/data/employee_store.dart';
import 'widgets/task_assign_sheet.dart';
import 'widgets/task_related_sheet.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? taskId;

  const CreateTaskScreen({
    super.key,
    this.taskId,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedPriority = 'Normal';
  String _selectedDueDate = 'Today';
  String _assignedTo = 'None';
  String _relatedTo = 'None';
  String? _attachedFileName;

  final priorities = ['Low', 'Normal', 'High', 'Urgent'];
  final dueDates = ['Today', 'Tomorrow', 'Next Week', 'No Due Date'];

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _titleController.text = 'Prepare Blue Wave Resort demo';
      _descController.text =
          'Create product demo presentation for the upcoming meeting with Blue Wave Resort management team.';
      _selectedPriority = 'High';
      _selectedDueDate = 'Today';
      _assignedTo = 'Most. Shahina Akter';
      _relatedTo = 'Lead';
      _attachedFileName = 'demo_presentation.pdf';
    } else if (!DemoSession.instance.isAdmin) {
      _assignedTo = EmployeeStore.instance.currentEmployee.name;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _openAssignSheet() {
    if (!DemoSession.instance.isAdmin) {
      NecToast.show(
        context,
        message: 'Only administrators can assign tasks to other team members',
        type: NecToastType.info,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskAssignSheet(
        selectedAssignee: _assignedTo,
        onSelected: (val) {
          setState(() {
            _assignedTo = val;
          });
        },
      ),
    );
  }

  void _openRelatedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskRelatedSheet(
        selectedRelated: _relatedTo,
        onSelected: (val) {
          setState(() {
            _relatedTo = val;
          });
        },
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
                  final file = result.files.first;
                  setState(() {
                    _attachedFileName = file.name;
                  });
                  if (mounted) {
                    NecToast.show(
                      context,
                      message: 'Attached ${file.name}',
                      type: NecToastType.success,
                    );
                  }
                }
              } catch (_) {
                setState(() {
                  _attachedFileName = 'document_attachment.pdf';
                });
                if (mounted) {
                  NecToast.show(
                    context,
                    message: 'Attached document_attachment.pdf',
                    type: NecToastType.info,
                  );
                }
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
                  setState(() {
                    _attachedFileName = image.name;
                  });
                  if (mounted) {
                    NecToast.show(
                      context,
                      message: 'Attached ${image.name}',
                      type: NecToastType.success,
                    );
                  }
                }
              } catch (_) {
                setState(() {
                  _attachedFileName = 'gallery_image.jpg';
                });
                if (mounted) {
                  NecToast.show(
                    context,
                    message: 'Attached gallery_image.jpg',
                    type: NecToastType.info,
                  );
                }
              }
            },
            child: const Text('Photo Gallery'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final picker = ImagePicker();
                final photo =
                    await picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    _attachedFileName = photo.name;
                  });
                  if (mounted) {
                    NecToast.show(
                      context,
                      message: 'Attached ${photo.name}',
                      type: NecToastType.success,
                    );
                  }
                }
              } catch (_) {
                setState(() {
                  _attachedFileName = 'camera_photo.jpg';
                });
                if (mounted) {
                  NecToast.show(
                    context,
                    message: 'Attached camera_photo.jpg',
                    type: NecToastType.info,
                  );
                }
              }
            },
            child: const Text('Camera Photo'),
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
    final isEditMode = widget.taskId != null;

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
                  isEditMode ? 'Edit Task' : 'Create Task',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Task title *',
                              hintStyle: TextStyle(
                                color: nec.textTertiary,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descController,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Description (optional)',
                              hintStyle: TextStyle(
                                color: nec.textTertiary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PRIORITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: priorities.map((p) {
                        final isSelected = _selectedPriority == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPriority = p;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? nec.brand.withValues(alpha: 0.15)
                                    : nec.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? nec.brand
                                      : nec.separator.withValues(alpha: 0.3),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                p,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color:
                                      isSelected ? nec.brand : nec.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'DUE DATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dueDates.map((d) {
                        final isSelected = _selectedDueDate == d;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDueDate = d;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? nec.brand.withValues(alpha: 0.15)
                                  : nec.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? nec.brand
                                    : nec.separator.withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? nec.brand : nec.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              'Assigned To',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: nec.textPrimary,
                              ),
                            ),
                            subtitle: !DemoSession.instance.isAdmin
                                ? Text(
                                    'Assigned to you (Staff)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nec.brand,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _assignedTo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: DemoSession.instance.isAdmin
                                        ? nec.textTertiary
                                        : nec.textPrimary,
                                    fontWeight: DemoSession.instance.isAdmin
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  DemoSession.instance.isAdmin
                                      ? CupertinoIcons.chevron_right
                                      : CupertinoIcons.lock_fill,
                                  size: DemoSession.instance.isAdmin ? 16 : 13,
                                  color: nec.textTertiary,
                                ),
                              ],
                            ),
                            onTap: _openAssignSheet,
                          ),
                          Divider(
                            height: 1,
                            color: nec.separator.withValues(alpha: 0.2),
                            indent: 16,
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              'Related To',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: nec.textPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _relatedTo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: nec.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                              ],
                            ),
                            onTap: _openRelatedSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ATTACHMENT (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: nec.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          _attachedFileName ?? 'Add Attachment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _attachedFileName != null
                                ? nec.textPrimary
                                : nec.textTertiary,
                          ),
                        ),
                        trailing: _attachedFileName != null
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _attachedFileName = null;
                                  });
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: NecButton(
                label: isEditMode ? 'Save Changes' : 'Create Task',
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) {
                    NecToast.show(
                      context,
                      message: 'Please enter a task title',
                      type: NecToastType.error,
                    );
                    return;
                  }
                  context.pop();
                  NecToast.show(
                    context,
                    message: isEditMode
                        ? 'Task updated successfully'
                        : 'Task created successfully',
                    type: NecToastType.success,
                  );
                },
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
