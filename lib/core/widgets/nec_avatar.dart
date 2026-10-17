import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class NecAvatar extends StatefulWidget {
  final String? initials;
  final double size;
  final String? photoBase64;
  final String? assetPath;
  final String? photoUrl;
  final Color? backgroundColor;

  const NecAvatar(
      {super.key,
      this.initials,
      this.size = 36,
      this.photoBase64,
      this.assetPath,
      this.photoUrl,
      this.backgroundColor});

  @override
  State<NecAvatar> createState() => _NecAvatarState();
}

class _NecAvatarState extends State<NecAvatar> {
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _decodePhoto();
  }

  @override
  void didUpdateWidget(covariant NecAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBase64 != widget.photoBase64) _decodePhoto();
  }

  void _decodePhoto() {
    try {
      _photoBytes =
          widget.photoBase64 == null ? null : base64Decode(widget.photoBase64!);
    } on FormatException {
      _photoBytes = null;
    }
  }

  Color get _bg {
    final colors = [
      const Color(0xFF0071E3),
      const Color(0xFF5856D6),
      const Color(0xFF30B0C7),
      const Color(0xFFFF9F0A),
      const Color(0xFF34C759),
      const Color(0xFFBF5AF2)
    ];
    return colors[(widget.initials?.isNotEmpty == true
            ? widget.initials!.codeUnitAt(0)
            : 0) %
        colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = Text(
        (widget.initials?.isNotEmpty == true ? widget.initials! : '?')
            .characters
            .take(2)
            .join()
            .toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w600));
    Widget content = fallback;
    if (widget.assetPath != null) {
      final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
      content = ClipOval(
        child: Image.asset(widget.assetPath!,
            width: size,
            height: size,
            cacheWidth: pixels,
            cacheHeight: pixels,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Center(child: fallback)),
      );
    } else if (_photoBytes != null) {
      content = ClipOval(
          child: Image.memory(_photoBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Center(child: fallback)));
    } else if (widget.photoUrl != null) {
      content = ClipOval(
          child: Image.network(widget.photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: fallback)));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: widget.backgroundColor ?? _bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: content,
    );
  }
}
