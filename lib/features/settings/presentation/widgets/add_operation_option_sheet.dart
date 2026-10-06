import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/follow_up_visit_settings_store.dart';
import '../../domain/models/operation_option.dart';

class AddOperationOptionSheet extends StatefulWidget {
  final OperationOptionGroup group;
  final FollowUpVisitSettingsStore settings;

  const AddOperationOptionSheet({
    super.key,
    required this.group,
    required this.settings,
  });

  @override
  State<AddOperationOptionSheet> createState() =>
      _AddOperationOptionSheetState();
}

class _AddOperationOptionSheetState extends State<AddOperationOptionSheet> {
  final _controller = TextEditingController();

  bool get _duplicate =>
      widget.settings.contains(widget.group, _controller.text);

  bool get _canAdd => _controller.text.trim().isNotEmpty && !_duplicate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (!_canAdd) return;
    if (widget.settings.add(widget.group, _controller.text)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.42,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: nec.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Add ${widget.group.singular}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                ),
                Divider(height: 1, color: nec.separator),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _controller,
                          placeholder: widget.group.placeholder,
                          placeholderStyle: TextStyle(color: nec.textTertiary),
                          style:
                              TextStyle(color: nec.textPrimary, fontSize: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: nec.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          maxLength: 60,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _add(),
                        ),
                        if (_duplicate) ...[
                          const SizedBox(height: 8),
                          Text(
                            'This ${widget.group.singular.toLowerCase()} already exists.',
                            style: TextStyle(
                                fontSize: 12, color: nec.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: nec.brand,
                            disabledColor:
                                nec.textTertiary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(25),
                            onPressed: _canAdd ? _add : null,
                            child: Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    _canAdd ? Colors.white : nec.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
