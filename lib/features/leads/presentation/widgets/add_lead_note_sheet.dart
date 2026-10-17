import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/lead_store.dart';

Future<void> showLeadNoteSheet(
  BuildContext context, {
  required String leadId,
  String title = 'Add Lead Note',
  String hintText = 'Enter note details...',
  VoidCallback? onNoteAdded,
}) async {
  final nec = Theme.of(context).extension<NecColors>()!;
  final controller = TextEditingController();
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return Material(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: nec.separator,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.xmark_circle_fill,
                              color: nec.textTertiary, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: nec.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: nec.separator.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        minLines: 3,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textPrimary,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: nec.textTertiary,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final text = controller.text.trim();
                                if (text.isEmpty) {
                                  NecToast.show(ctx,
                                      message: 'Please enter a note',
                                      type: NecToastType.error);
                                  return;
                                }
                                setModalState(() => submitting = true);
                                try {
                                  await LeadStore.instance
                                      .addNote(leadId, text);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (context.mounted) {
                                    NecToast.show(context,
                                        message: 'Note saved successfully',
                                        type: NecToastType.success);
                                  }
                                  onNoteAdded?.call();
                                } catch (e) {
                                  setModalState(() => submitting = false);
                                  if (ctx.mounted) {
                                    NecToast.show(ctx,
                                        message: 'Failed to add note: $e',
                                        type: NecToastType.error);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nec.brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Note',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
