import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/chat_attachment.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? replyName;
  final String? replyPreview;
  final List<PendingChatAttachment> attachments;
  final bool canSend;
  final bool enabled;
  final bool sending;
  final bool picking;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;
  final ValueChanged<int> onRemoveAttachment;

  const ChatComposer(
      {super.key,
      required this.controller,
      required this.focusNode,
      this.replyName,
      this.replyPreview,
      required this.attachments,
      required this.canSend,
      required this.enabled,
      required this.sending,
      required this.picking,
      required this.onAttach,
      required this.onSend,
      required this.onCancelReply,
      required this.onRemoveAttachment});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final busy = sending || picking;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: nec.surface,
          border: Border(top: BorderSide(color: nec.separator, width: .5))),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (replyPreview != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                          color: nec.brand.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                              left: BorderSide(color: nec.brand, width: 3))),
                      child: Row(children: [
                        Icon(CupertinoIcons.reply, color: nec.brand, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Replying to $replyName',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: nec.brand,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(replyPreview!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: nec.textSecondary,
                                              fontSize: 12)),
                                    ]))),
                        CupertinoButton(
                            padding: const EdgeInsets.all(10),
                            onPressed: busy ? null : onCancelReply,
                            child: Icon(CupertinoIcons.xmark_circle_fill,
                                color: nec.textTertiary, size: 20)),
                      ]))),
            if (attachments.isNotEmpty)
              SizedBox(
                  height: 86,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachments.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final attachment = attachments[index];
                        return Container(
                            width: 180,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                                color: nec.bg,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: attachment.isImage
                                      ? Image.memory(attachment.bytes,
                                          width: 42,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                              CupertinoIcons.doc,
                                              color: nec.brand,
                                              size: 32))
                                      : Icon(CupertinoIcons.doc_fill,
                                          color: nec.brand, size: 30)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(attachment.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: nec.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text(
                                        '${(attachment.bytes.length / 1024).ceil()} KB',
                                        style: TextStyle(
                                            color: nec.textTertiary,
                                            fontSize: 10)),
                                  ])),
                              CupertinoButton(
                                  padding: const EdgeInsets.all(7),
                                  onPressed: busy
                                      ? null
                                      : () => onRemoveAttachment(index),
                                  child: Icon(CupertinoIcons.xmark_circle_fill,
                                      color: nec.textTertiary, size: 17)),
                            ]));
                      })),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Tooltip(
                  message: 'Add photo or file',
                  child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: enabled && !busy ? onAttach : null,
                      child: Container(
                          width: 42,
                          height: 44,
                          alignment: Alignment.center,
                          child: picking
                              ? CupertinoActivityIndicator(color: nec.brand)
                              : Icon(CupertinoIcons.plus_circle_fill,
                                  size: 28,
                                  color: enabled && !busy
                                      ? nec.brand
                                      : nec.textTertiary)))),
              const SizedBox(width: 5),
              Expanded(
                  child: CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled && !busy,
                placeholder:
                    attachments.isEmpty ? 'Message…' : 'Add a caption…',
                minLines: 1,
                maxLines: 4,
                maxLength: 4000,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                    color: nec.textPrimary, fontSize: 15, height: 1.35),
                placeholderStyle: TextStyle(color: nec.textTertiary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                    color: nec.bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: nec.separator.withValues(alpha: .45))),
              )),
              const SizedBox(width: 8),
              Tooltip(
                  message: 'Send message',
                  child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: canSend ? onSend : null,
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: canSend || sending
                                  ? nec.brand
                                  : nec.textTertiary.withValues(alpha: .12),
                              shape: BoxShape.circle),
                          child: sending
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white)
                              : Icon(CupertinoIcons.paperplane_fill,
                                  size: 21,
                                  color: canSend
                                      ? Colors.white
                                      : nec.textTertiary)))),
            ]),
          ])),
    );
  }
}
