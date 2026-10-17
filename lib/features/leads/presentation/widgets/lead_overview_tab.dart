import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/services/phone_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_badge.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/lead_store.dart';
import '../../domain/models/lead.dart';
import 'add_lead_note_sheet.dart';

class LeadOverviewTab extends StatefulWidget {
  final Lead? lead;
  final Map<String, dynamic>? details;
  final bool isUnassigned;
  final String companyName;
  final String assignedEmployee;
  final VoidCallback? onChangeAssigned;
  final String? location;
  final String? leadType;
  final double? latitude;
  final double? longitude;

  const LeadOverviewTab({
    super.key,
    this.lead,
    this.details,
    this.isUnassigned = true,
    required this.companyName,
    this.assignedEmployee = 'Unassigned',
    this.onChangeAssigned,
    this.location,
    this.leadType,
    this.latitude,
    this.longitude,
  });

  @override
  State<LeadOverviewTab> createState() => _LeadOverviewTabState();
}

class _LeadOverviewTabState extends State<LeadOverviewTab> {
  Lead? get _lead => widget.lead;

  bool get _unassigned => widget.isUnassigned;

  String get _assignedEmployee => widget.assignedEmployee;

  void _openChangeEmployeeSheet() {
    if (DemoSession.instance.isAdmin) widget.onChangeAssigned?.call();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRowItem({
    required BuildContext context,
    required String label,
    required Widget valueWidget,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: nec.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: DefaultTextStyle.merge(
                          textAlign: TextAlign.end,
                          child: valueWidget,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: nec.textTertiary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: nec.separator.withValues(alpha: 0.2),
            indent: 16,
          ),
      ],
    );
  }

  void _callPhone(String phone) async {
    await PhoneService.call(context, phone);
  }

  void _sendEmail(String email) async {
    await PhoneService.mail(context, email);
  }

  void _openStatusPicker() {
    if (_lead == null) return;
    final nec = Theme.of(context).extension<NecColors>()!;
    final statuses = [
      'New',
      'Follow-up',
      'Interested',
      'Visit Scheduled',
      'Proposal',
      'Negotiation',
      'Won',
      'Lost',
    ];

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Text(
                      'Change Lead Status',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                  ),
                  ...statuses.map((st) {
                    final isSelected =
                        st.toLowerCase() == _lead!.status.toLowerCase();
                    return ListTile(
                      leading: LeadStatusBadge(status: st, small: true),
                      trailing: isSelected
                          ? Icon(CupertinoIcons.checkmark,
                              color: nec.brand, size: 20)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await LeadStore.instance.updateStatus(_lead!.id, st);
                          if (mounted) {
                            NecToast.show(
                              context,
                              message: 'Status updated to $st',
                              type: NecToastType.success,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            NecToast.show(
                              context,
                              message: 'Failed to update status',
                              type: NecToastType.error,
                            );
                          }
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPriorityPicker() {
    if (_lead == null) return;
    final nec = Theme.of(context).extension<NecColors>()!;
    final priorities = ['Urgent', 'High', 'Normal', 'Low'];

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Text(
                      'Change Priority',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                  ),
                  ...priorities.map((pr) {
                    final isSelected =
                        pr.toLowerCase() == _lead!.priority.toLowerCase();
                    return ListTile(
                      leading: PriorityBadge(priority: pr),
                      trailing: isSelected
                          ? Icon(CupertinoIcons.checkmark,
                              color: nec.brand, size: 20)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await LeadStore.instance
                              .updatePriority(_lead!.id, pr);
                          if (mounted) {
                            NecToast.show(
                              context,
                              message: 'Priority updated to $pr',
                              type: NecToastType.success,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            NecToast.show(
                              context,
                              message: 'Failed to update priority',
                              type: NecToastType.error,
                            );
                          }
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddNoteDialog() {
    if (_lead == null) return;
    showLeadNoteSheet(
      context,
      leadId: _lead!.id,
      title: 'Add Lead Note',
      hintText: 'Enter note details...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final contactName = _lead?.contactName ??
        (widget.details?['lead']?['contact']?['name'] as String?) ??
        'Not specified';
    final phone = _lead?.phone ??
        (widget.details?['lead']?['contact']?['phone'] as String?);
    final email = _lead?.email ??
        (widget.details?['lead']?['contact']?['email'] as String?);
    final company = _lead?.company ?? widget.companyName;
    final type = _lead?.type ?? widget.leadType ?? 'Hotel';
    final location = _lead?.location ?? widget.location ?? "Cox's Bazar";
    final lat = _lead?.latitude ?? widget.latitude;
    final lng = _lead?.longitude ?? widget.longitude;

    final currentStatus = _lead?.status ?? 'New';
    final currentPriority = _lead?.priority ?? 'Normal';
    final source = _lead?.source ?? 'Direct';

    final notesList = widget.details?['notes'] as List?;
    final latestNote = (notesList != null && notesList.isNotEmpty)
        ? notesList.first as Map?
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'CONTACT'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Person',
                  valueWidget: Text(
                    contactName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Phone',
                  valueWidget: Text(
                    phone != null && phone.isNotEmpty ? phone : 'Add Phone',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: phone != null && phone.isNotEmpty
                          ? nec.brand
                          : nec.textTertiary,
                    ),
                  ),
                  onTap: phone != null && phone.isNotEmpty
                      ? () => _callPhone(phone)
                      : (_lead != null
                          ? () => context.push('/edit-lead/${_lead!.id}')
                          : null),
                  showDivider: email != null && email.isNotEmpty,
                ),
                if (email != null && email.isNotEmpty)
                  _buildRowItem(
                    context: context,
                    label: 'Email',
                    valueWidget: Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: nec.brand,
                      ),
                    ),
                    onTap: () => _sendEmail(email),
                    showDivider: false,
                  ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'BUSINESS'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Company',
                  valueWidget: Text(
                    company,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Type',
                  valueWidget: Text(
                    type,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Location',
                  valueWidget: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  showDivider: lat != null && lng != null,
                ),
                if (lat != null && lng != null)
                  _buildRowItem(
                    context: context,
                    label: 'Coordinates',
                    valueWidget: Text(
                      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: nec.brand,
                      ),
                    ),
                    showDivider: false,
                  ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'BUSINESS PROFILE'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                _lead?.interestedPlan != null ||
                        (_lead?.totalRooms != null && _lead!.totalRooms! > 0)
                    ? 'Plan: ${_lead?.interestedPlan ?? 'Custom'} · Rooms: ${_lead?.totalRooms ?? 0}'
                    : '+ Add qualification details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
              trailing: Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: nec.textTertiary,
              ),
              onTap: () {
                if (_lead != null) {
                  context.push('/edit-lead/${_lead!.id}');
                }
              },
            ),
          ),
          _buildSectionHeader(context, 'LEAD'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildRowItem(
                  context: context,
                  label: 'Status',
                  valueWidget: LeadStatusBadge(
                    status: currentStatus,
                    small: true,
                  ),
                  onTap: _openStatusPicker,
                ),
                _buildRowItem(
                  context: context,
                  label: 'Source',
                  valueWidget: Text(
                    source,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                _buildRowItem(
                  context: context,
                  label: 'Priority',
                  valueWidget: PriorityBadge(priority: currentPriority),
                  onTap: _openPriorityPicker,
                ),
                _buildRowItem(
                  context: context,
                  label: 'Created',
                  valueWidget: Text(
                    _lead != null
                        ? '${_lead!.createdAt.day}/${_lead!.createdAt.month}/${_lead!.createdAt.year}'
                        : 'Today',
                    style: TextStyle(
                      fontSize: 14,
                      color: nec.textPrimary,
                    ),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'OWNERSHIP'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (!_unassigned)
                    NecAvatar(
                      initials: EmployeeStore.instance
                              .byId(widget.lead?.assignedEmployeeId ?? '')
                              ?.avatarInitials ??
                          Employee.initialsFor(_assignedEmployee),
                      photoBase64: EmployeeStore.instance
                          .byId(widget.lead?.assignedEmployeeId ?? '')
                          ?.photoBase64,
                      photoUrl: EmployeeStore.instance
                          .byId(widget.lead?.assignedEmployeeId ?? '')
                          ?.photoUrl,
                      assetPath: EmployeeStore.instance
                          .byId(widget.lead?.assignedEmployeeId ?? '')
                          ?.avatarAsset,
                      size: 36,
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (_unassigned ? AppColors.warning : nec.brand)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _unassigned
                            ? CupertinoIcons.exclamationmark_triangle
                            : CupertinoIcons.person_fill,
                        color: _unassigned ? AppColors.warning : nec.brand,
                        size: 18,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _unassigned ? 'Unassigned' : _assignedEmployee,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _unassigned
                                ? AppColors.warning
                                : nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _unassigned
                              ? 'No employee assigned'
                              : 'Assigned employee',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (DemoSession.instance.isAdmin)
                    TextButton(
                      onPressed: _openChangeEmployeeSheet,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (latestNote != null) ...[
            _buildSectionHeader(context, 'LATEST NOTE'),
            Builder(builder: (context) {
              final authorMap = latestNote['author'] is Map
                  ? latestNote['author'] as Map
                  : null;
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
              final time = latestNote['created_at']?.toString() ?? '';

              return Container(
                width: double.infinity,
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
                              Text(
                                time.isNotEmpty ? 'Note · $time' : 'Lead Note',
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
                      '"${latestNote['body'] ?? ''}"',
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
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openAddNoteDialog,
              icon: Icon(CupertinoIcons.add, size: 16, color: nec.brand),
              label: Text(
                'Add Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: nec.brand,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: nec.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: nec.separator.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
