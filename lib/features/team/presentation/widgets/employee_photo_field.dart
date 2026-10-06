import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_avatar.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/employee_photo_picker.dart';
import '../../domain/models/employee.dart';

class EmployeePhotoField extends StatefulWidget {
  final String name;
  final String? photoBase64;
  final ValueChanged<String?> onChanged;
  final ValueChanged<bool>? onBusyChanged;

  const EmployeePhotoField(
      {super.key,
      required this.name,
      required this.photoBase64,
      required this.onChanged,
      this.onBusyChanged});

  @override
  State<EmployeePhotoField> createState() => _EmployeePhotoFieldState();
}

class _EmployeePhotoFieldState extends State<EmployeePhotoField> {
  bool _busy = false;

  Future<void> _choose() async {
    final source = await EmployeePhotoPicker.chooseSource(context,
        hasPhoto: widget.photoBase64 != null);
    if (source == null || !mounted) return;
    if (source == EmployeePhotoSource.remove) {
      widget.onChanged(null);
      return;
    }
    setState(() => _busy = true);
    widget.onBusyChanged?.call(true);
    try {
      final photo = await EmployeePhotoPicker.pick(source);
      if (photo != null && mounted) widget.onChanged(photo);
    } catch (error) {
      if (mounted) {
        NecToast.show(context,
            message: error is FormatException
                ? error.message
                : 'Unable to select this photo. Try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Column(children: [
      Semantics(
        button: true,
        label: 'Change employee photo',
        child: GestureDetector(
          onTap: _busy ? null : _choose,
          child: Stack(children: [
            NecAvatar(
                initials: Employee.initialsFor(widget.name),
                size: 88,
                backgroundColor: nec.brand,
                photoBase64: widget.photoBase64),
            Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: nec.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: nec.bg, width: 2)),
                  child: _busy
                      ? const CupertinoActivityIndicator(
                          color: Colors.white, radius: 8)
                      : const Icon(CupertinoIcons.camera_fill,
                          size: 16, color: Colors.white),
                )),
          ]),
        ),
      ),
      CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          onPressed: _busy ? null : _choose,
          child: Text(widget.photoBase64 == null ? 'Add Photo' : 'Change Photo',
              style: TextStyle(fontSize: 13, color: nec.brand))),
    ]);
  }
}
