import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../team/data/employee_store.dart';
import '../../domain/models/chat_message.dart';
import 'message_attachment_view.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final VoidCallback onActions;
  final VoidCallback onReply;
  final VoidCallback onOpenReply;
  final ValueChanged<String> onReact;

  const MessageBubble(
      {super.key,
      required this.message,
      required this.mine,
      required this.onActions,
      required this.onReply,
      required this.onOpenReply,
      required this.onReact});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final foreground = mine ? Colors.white : nec.textPrimary;
    final secondary =
        mine ? Colors.white.withValues(alpha: .7) : nec.textTertiary;
    final counts = <String, int>{};
    for (final emoji in message.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final quote = message.reply;
    final replyName = quote == null
        ? ''
        : quote.senderId == DemoSession.instance.employeeId
            ? 'You'
            : EmployeeStore.instance.byId(quote.senderId)?.name ?? 'Teammate';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: onActions,
                  onDoubleTap: message.isDeleted ? null : () => onReact('👍'),
                  onHorizontalDragEnd: message.isDeleted
                      ? null
                      : (details) {
                          if ((details.primaryVelocity ?? 0).abs() > 180) {
                            onReply();
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: BoxDecoration(
                        color: message.isDeleted
                            ? nec.surface
                            : mine
                                ? nec.brand
                                : nec.surface,
                        borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(mine ? 18 : 5),
                            bottomRight: Radius.circular(mine ? 5 : 18))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.pinnedAt != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.pin_fill,
                                          size: 11, color: secondary),
                                      const SizedBox(width: 4),
                                      Text('Pinned',
                                          style: TextStyle(
                                              color: secondary, fontSize: 10)),
                                    ])),
                          if (quote != null && !message.isDeleted)
                            GestureDetector(
                                onTap: onOpenReply,
                                child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: mine
                                            ? Colors.white
                                                .withValues(alpha: .13)
                                            : nec.bg,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border(
                                            left: BorderSide(
                                                color: mine
                                                    ? Colors.white
                                                    : nec.brand,
                                                width: 3))),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(replyName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: mine
                                                      ? Colors.white
                                                      : nec.brand,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          Text(quote.preview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: secondary,
                                                  fontSize: 12,
                                                  height: 1.3)),
                                        ]))),
                          if (!message.isDeleted)
                            for (final attachment in message.attachments)
                              MessageAttachmentView(
                                  key: ValueKey(attachment.id),
                                  attachment: attachment,
                                  mine: mine),
                          if (message.isDeleted)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(CupertinoIcons.nosign,
                                  color: nec.textTertiary, size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                  child: Text('Message deleted',
                                      style: TextStyle(
                                          color: nec.textTertiary,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic))),
                            ])
                          else if (message.text.isNotEmpty)
                            Text(message.text,
                                style: TextStyle(
                                    color: foreground,
                                    fontSize: 15,
                                    height: 1.4)),
                          const SizedBox(height: 6),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(DateFormat('h:mm a').format(message.sentAt),
                                style: TextStyle(
                                    color: message.isDeleted
                                        ? nec.textTertiary
                                        : secondary,
                                    fontSize: 10)),
                            if (mine && !message.isDeleted) ...[
                              const SizedBox(width: 5),
                              Tooltip(
                                  message:
                                      message.readAt == null ? 'Sent' : 'Read',
                                  child: Icon(
                                      message.readAt == null
                                          ? CupertinoIcons.checkmark
                                          : CupertinoIcons
                                              .checkmark_circle_fill,
                                      color: secondary,
                                      size: 12)),
                            ],
                          ]),
                        ]),
                  ),
                ),
                if (counts.isNotEmpty && !message.isDeleted)
                  Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Wrap(spacing: 5, runSpacing: 5, children: [
                        for (final entry in counts.entries)
                          GestureDetector(
                              onTap: () => onReact(entry.key),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: message.reactions[DemoSession.instance.employeeId] ==
                                              entry.key
                                          ? nec.brand.withValues(alpha: .1)
                                          : nec.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                              message.reactions[DemoSession.instance.employeeId] ==
                                                      entry.key
                                                  ? nec.brand
                                                  : nec.separator)),
                                  child: Text('${entry.key} ${entry.value}',
                                      style: TextStyle(
                                          color: nec.textPrimary,
                                          fontSize: 12)))),
                      ])),
              ]),
        ),
      ),
    );
  }
}
