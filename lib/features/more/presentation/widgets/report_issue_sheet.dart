import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/issue.dart';

class ReportIssueSheet extends StatefulWidget {
  const ReportIssueSheet({super.key});

  @override
  State<ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<ReportIssueSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedPriority = 'Normal';
  String? _selectedCategory;
  String? _selectedAssignee = 'Auto-assign';
  String? _selectedAssigneeInitials;
  String? _selectedRelatedTo = 'None';
  String? _attachedFileName;

  final priorities = ['Low', 'Normal', 'High', 'Urgent'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCategorySheet() {
    final categories = [
      'Bug',
      'Technical',
      'Customer Support',
      'Feature Request',
      'Payment',
      'Hotel/Client',
      'Mobile App',
      'Website',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Issue Category',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
                ...categories.map(
                  (cat) => Column(
                    children: [
                      ListTile(
                        title: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedCategory == cat
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedCategory == cat
                                ? nec.brand
                                : nec.textPrimary,
                          ),
                        ),
                        trailing: _selectedCategory == cat
                            ? Icon(CupertinoIcons.checkmark,
                                color: nec.brand, size: 18)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.15),
                        indent: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssignToSheet() {
    if (!DemoSession.instance.isAdmin) {
      NecToast.show(
        context,
        message: 'Only administrators can assign issues to team members',
        type: NecToastType.info,
      );
      return;
    }
    final assignees = [
      (
        'Auto-assign',
        '',
        '',
        CupertinoIcons.minus_circle,
      ),
      (
        'Mahmud Hasan',
        'General Manager',
        'MH',
        null,
      ),
      (
        'Most. Shahina Akter',
        'Digital Marketing Executive',
        'MS',
        null,
      ),
      (
        'Md. Yeapas',
        'Senior Software Engineer',
        'MY',
        null,
      ),
      (
        'Rashidul Islam',
        'Sales Executive',
        'RI',
        null,
      ),
      (
        'MD. Abdul Hamim',
        'Flutter Developer',
        'MA',
        null,
      ),
      (
        'Tania Rahman',
        'Support Lead',
        'TR',
        null,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Assign To',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
                ...assignees.map(
                  (item) {
                    final name = item.$1;
                    final role = item.$2;
                    final initials = item.$3;
                    final isSelected = _selectedAssignee == name ||
                        (_selectedAssignee == null && name == 'Auto-assign');

                    return Column(
                      children: [
                        ListTile(
                          leading: initials.isNotEmpty
                              ? NecAvatar(initials: initials, size: 32)
                              : Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: nec.bg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.$4 ?? CupertinoIcons.person,
                                    color: nec.textSecondary,
                                    size: 18,
                                  ),
                                ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                          ),
                          subtitle: role.isNotEmpty
                              ? Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: nec.textTertiary,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(CupertinoIcons.checkmark,
                                  color: nec.brand, size: 18)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedAssignee = name;
                              _selectedAssigneeInitials = initials;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.15),
                          indent: 16,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRelatedToSheet() {
    final options = [
      'None',
      'Hotel/Client',
      'Lead',
      'Internal',
      'Mobile App',
      'Website',
      'Backend',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Related To',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
                ...options.map(
                  (opt) => Column(
                    children: [
                      ListTile(
                        title: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedRelatedTo == opt
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedRelatedTo == opt
                                ? nec.brand
                                : nec.textPrimary,
                          ),
                        ),
                        trailing: _selectedRelatedTo == opt
                            ? Icon(CupertinoIcons.checkmark,
                                color: nec.brand, size: 18)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedRelatedTo = opt;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.15),
                        indent: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final nec = Theme.of(context).extension<NecColors>()!;
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add Attachment',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: nec.separator.withValues(alpha: 0.3)),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.camera,
                      color: AppColors.brandLight,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Take Photo (Camera)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _attachedFileName =
                          'camera_photo_${DateTime.now().second}.jpg';
                    });
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAttachment();
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    'Browse Files',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAttachment();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'txt'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFileName = result.files.first.name;
        });
      }
    } catch (_) {
      setState(() {
        _attachedFileName = 'screenshot_issue.png';
      });
    }
  }

  void _submitIssue() {
    if (_titleController.text.trim().isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter an issue title',
        type: NecToastType.error,
      );
      return;
    }

    final newIssue = Issue(
      id: 'NEC-${135 + (DateTime.now().millisecondsSinceEpoch % 100)}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priority: _selectedPriority,
      status: 'Reported',
      category: _selectedCategory ?? 'Mobile App',
      project: _selectedRelatedTo != null && _selectedRelatedTo != 'None'
          ? _selectedRelatedTo!
          : 'NEC TEAM App',
      assigneeName:
          _selectedAssignee == 'Auto-assign' ? null : _selectedAssignee,
      assigneeInitials: _selectedAssigneeInitials,
      date: 'Sep 28, 2026',
      scopeMine: true,
      scopeTeam: true,
      hasRedDot: _selectedPriority == 'Urgent' || _selectedPriority == 'High',
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newIssue);
    } else {
      context.pop(newIssue);
    }

    NecToast.show(
      context,
      message: 'Issue reported successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.pop();
                        }
                      },
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
                        'Report Issue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: nec.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _titleController,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Issue title *',
                                hintStyle: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                                hintText:
                                    'Describe the issue in detail — what happened, when, and what was affected...',
                                hintStyle: TextStyle(
                                  color: nec.textTertiary,
                                  fontSize: 14,
                                  height: 1.35,
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
                          final pColor = p == 'Urgent'
                              ? AppColors.error
                              : p == 'High'
                                  ? AppColors.warning
                                  : nec.brand;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = p;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? pColor.withValues(alpha: 0.15)
                                      : nec.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? pColor
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
                                        isSelected ? pColor : nec.textPrimary,
                                  ),
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
                              title: RichText(
                                text: TextSpan(
                                  text: 'Category ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: nec.textPrimary,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCategory ?? 'Select',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedCategory != null
                                          ? nec.textPrimary
                                          : nec.textTertiary,
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
                              onTap: _showCategorySheet,
                            ),
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.2),
                              indent: 16,
                            ),
                            ListTile(
                              title: Text(
                                'Assign To',
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
                                    _selectedAssignee ?? 'Select',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedAssignee != null
                                          ? nec.textPrimary
                                          : nec.textTertiary,
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
                              onTap: _showAssignToSheet,
                            ),
                            Divider(
                              height: 1,
                              color: nec.separator.withValues(alpha: 0.2),
                              indent: 16,
                            ),
                            ListTile(
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
                                    _selectedRelatedTo ?? 'None',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedRelatedTo != null &&
                                              _selectedRelatedTo != 'None'
                                          ? nec.textPrimary
                                          : nec.textTertiary,
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
                              onTap: _showRelatedToSheet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Reported issues go to the Issues queue and will be assigned to the right team member. Urgent issues are escalated automatically.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            height: 1.35,
                          ),
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
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.paperclip,
                              color: AppColors.error,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            _attachedFileName ?? 'Add Screenshot or File',
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
                              : const Icon(
                                  CupertinoIcons.add_circled,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                          onTap: _showAttachmentSourcePicker,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: NecButton(
                  label: 'Submit Issue',
                  onPressed: _submitIssue,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
