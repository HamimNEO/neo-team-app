import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_photo_picker.dart';
import '../../../team/domain/models/employee.dart';
import '../../data/group_chat_store.dart';
import '../../domain/models/group_chat.dart';

Future<GroupChat?> showGroupChatEditor(BuildContext context,
        {required GroupChatKind kind, GroupChat? group}) =>
    showModalBottomSheet<GroupChat>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).extension<NecColors>()!.bg,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _GroupChatEditor(kind: kind, group: group));

class _GroupChatEditor extends StatefulWidget {
  const _GroupChatEditor({required this.kind, this.group});

  final GroupChatKind kind;
  final GroupChat? group;

  @override
  State<_GroupChatEditor> createState() => _GroupChatEditorState();
}

class _GroupChatEditorState extends State<_GroupChatEditor> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late final _description =
      TextEditingController(text: widget.group?.description ?? '');
  late final String _actor;
  late final String? _token;
  String? _scopeKey, _photo, _photoUrl;
  bool _saving = false, _picking = false, _removedPhoto = false;

  @override
  void initState() {
    super.initState();
    _actor = DemoSession.instance.employeeId;
    _token = DemoSession.instance.accessToken;
    _photo = widget.group?.photoBase64;
    _photoUrl = widget.group?.photoUrl;
    final eligible = GroupChatStore.instance.scopes
        .where((s) =>
            s.kind == widget.kind && GroupChatStore.instance.canManage(s))
        .toList();
    _scopeKey = widget.group?.scopeKey ?? eligible.firstOrNull?.key;
  }

  bool get _sameSession =>
      _actor == DemoSession.instance.employeeId &&
      _token == DemoSession.instance.accessToken;

  Future<void> _photoPicker() async {
    final hasImage = _photo != null || _photoUrl != null;
    final source = await showCupertinoModalPopup<EmployeePhotoSource>(
        context: context,
        builder: (c) => CupertinoActionSheet(
            title: const Text('Group image'),
            actions: [
              CupertinoActionSheetAction(
                  onPressed: () =>
                      Navigator.pop(c, EmployeePhotoSource.gallery),
                  child: const Text('Photo Library')),
              CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(c, EmployeePhotoSource.files),
                  child: const Text('Choose from Files')),
              if (hasImage)
                CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () =>
                        Navigator.pop(c, EmployeePhotoSource.remove),
                    child: const Text('Remove Image')),
            ],
            cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'))));
    if (!mounted || source == null || !_sameSession) return;
    if (source == EmployeePhotoSource.remove) {
      setState(() {
        _photo = null;
        _photoUrl = null;
        _removedPhoto = true;
      });
      return;
    }
    setState(() => _picking = true);
    try {
      final photo = await EmployeePhotoPicker.pick(source);
      if (mounted && _sameSession && photo != null) {
        setState(() {
          _photo = photo;
          _photoUrl = null;
          _removedPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _error(Object e) => NecToast.show(context,
      type: NecToastType.error,
      message: e is FormatException
          ? e.message
          : 'Unable to save this group. Try again.');

  Future<void> _save() async {
    if (_saving || _picking || !_sameSession) return;
    final scope = GroupChatStore.instance.scopes
        .where((s) => s.key == _scopeKey)
        .firstOrNull;
    if (scope == null) {
      _error(const FormatException('Select an available team or department.'));
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await GroupChatStore.instance.save(
          scope: scope,
          group: widget.group,
          name: _name.text,
          description: _description.text,
          photoBase64: _photo,
          removePhoto: _removedPhoto,
          photoUrl: _photoUrl);
      if (mounted && _sameSession) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final scopes = GroupChatStore.instance.scopes
        .where((s) =>
            s.kind == widget.kind && GroupChatStore.instance.canManage(s))
        .toList();
    final busy = _saving || _picking;
    final hasImage = _photo != null || _photoUrl != null;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .85),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(children: [
                    CupertinoButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    Expanded(
                        child: Text(
                            widget.group == null ? 'New Group' : 'Edit Group',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: nec.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600))),
                    CupertinoButton(
                        onPressed: busy || scopes.isEmpty ? null : _save,
                        child: _saving
                            ? const CupertinoActivityIndicator()
                            : Text(widget.group == null ? 'Create' : 'Save')),
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                                child: NecAvatar(
                                    initials: Employee.initialsFor(
                                        _name.text.isEmpty
                                            ? 'Group'
                                            : _name.text),
                                    photoBase64: _photo,
                                    photoUrl: _photoUrl,
                                    size: 76)),
                            CupertinoButton(
                                onPressed: busy ? null : _photoPicker,
                                child: _picking
                                    ? const CupertinoActivityIndicator()
                                    : Text(hasImage
                                        ? 'Change Group Image'
                                        : 'Add Group Image')),
                            Text(
                                widget.kind == GroupChatKind.team
                                    ? 'TEAM'
                                    : 'DEPARTMENT',
                                style: TextStyle(
                                    color: nec.textTertiary, fontSize: 12)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                                initialValue:
                                    scopes.any((s) => s.key == _scopeKey)
                                        ? _scopeKey
                                        : null,
                                isExpanded: true,
                                dropdownColor: nec.surface,
                                style: TextStyle(
                                    color: nec.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder()),
                                items: scopes
                                    .map((s) => DropdownMenuItem(
                                        value: s.key,
                                        child: Text(s.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: busy || widget.group != null
                                    ? null
                                    : (v) => setState(() => _scopeKey = v)),
                            const SizedBox(height: 20),
                            Text('Group name *',
                                style: TextStyle(
                                    color: nec.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                                controller: _name,
                                enabled: !busy,
                                maxLength: 120,
                                onChanged: (_) => setState(() {}),
                                padding: const EdgeInsets.all(12),
                                style: TextStyle(color: nec.textPrimary),
                                placeholder: 'e.g. Daily updates'),
                            const SizedBox(height: 20),
                            Text('Description',
                                style: TextStyle(
                                    color: nec.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                                controller: _description,
                                enabled: !busy,
                                maxLength: 1000,
                                minLines: 3,
                                maxLines: 5,
                                padding: const EdgeInsets.all(12),
                                style: TextStyle(color: nec.textPrimary),
                                placeholder: 'What is this group for?'),
                            const SizedBox(height: 16),
                            Text(
                                'Everyone in the selected ${widget.kind.name} can participate. Membership follows their team or department assignment.',
                                style: TextStyle(
                                    color: nec.textSecondary,
                                    fontSize: 12,
                                    height: 1.4)),
                          ]))),
            ])));
  }
}
