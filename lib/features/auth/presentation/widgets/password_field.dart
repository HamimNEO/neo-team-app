import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool newPassword;
  final bool readOnly;
  final String? hint;
  final Future<bool> Function()? onReveal;
  final VoidCallback? onHidden;
  const PasswordField(
      {super.key,
      required this.label,
      required this.controller,
      required this.validator,
      this.newPassword = true,
      this.readOnly = false,
      this.hint,
      this.onReveal,
      this.onHidden});
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField>
    with WidgetsBindingObserver {
  bool _obscured = true;
  bool _verifying = false;
  bool _foreground = true;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && !_obscured) _hide();
  }

  void _hide() {
    _revealTimer?.cancel();
    if (mounted) setState(() => _obscured = true);
    widget.onHidden?.call();
  }

  Future<void> _toggle() async {
    if (_verifying) return;
    if (!_obscured) {
      _hide();
      return;
    }
    setState(() => _verifying = true);
    try {
      final allowed = await widget.onReveal?.call() ?? true;
      if (mounted && allowed && _foreground) {
        setState(() => _obscured = false);
        if (widget.onReveal != null) {
          _revealTimer?.cancel();
          _revealTimer = Timer(const Duration(seconds: 30), _hide);
        }
      } else if (mounted && allowed) {
        widget.onHidden?.call();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label,
            style: TextStyle(
                color: nec.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          obscureText: _obscured,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: widget.readOnly
              ? null
              : [
                  widget.newPassword
                      ? AutofillHints.newPassword
                      : AutofillHints.password
                ],
          textInputAction: TextInputAction.next,
          style: TextStyle(color: nec.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint ??
                (widget.newPassword
                    ? 'At least 8 characters'
                    : 'Your current password'),
            filled: true,
            fillColor: nec.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nec.separator)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nec.brand)),
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Show password' : 'Hide password',
              icon: Icon(
                  _obscured ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  color: nec.brand,
                  size: 20),
              onPressed: _verifying ? null : _toggle,
            ),
          ),
        ),
      ]),
    );
  }
}
