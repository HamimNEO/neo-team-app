import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/chat_message.dart';

enum MessageAction { react, reply, pin, copy, delete }

class MessageActionChoice {
  final MessageAction action;
  final String? emoji;

  const MessageActionChoice(this.action, [this.emoji]);
}

Future<MessageActionChoice?> chooseMessageAction(
        BuildContext context, ChatMessage message) =>
    showModalBottomSheet<MessageActionChoice>(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final nec = Theme.of(context).extension<NecColors>()!;
          void choose(MessageAction action, [String? emoji]) =>
              Navigator.pop(context, MessageActionChoice(action, emoji));
          Widget action(IconData icon, String label, MessageAction value,
                  {bool destructive = false}) =>
              ListTile(
                  leading: Icon(icon,
                      color:
                          destructive ? CupertinoColors.systemRed : nec.brand,
                      size: 22),
                  title: Text(label,
                      style: TextStyle(
                          color: destructive
                              ? CupertinoColors.systemRed
                              : nec.textPrimary,
                          fontSize: 15)),
                  onTap: () => choose(value));
          return Material(
            color: nec.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 10),
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: nec.textTertiary.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(4))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Text(message.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: nec.textSecondary, fontSize: 13))),
                  if (!message.isDeleted) ...[
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final emoji in ChatMessage.reactionOptions)
                            CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    choose(MessageAction.react, emoji),
                                child: Container(
                                    width: 42,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: message.reactions[DemoSession
                                                    .instance.employeeId] ==
                                                emoji
                                            ? nec.brand.withValues(alpha: .15)
                                            : nec.bg,
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: Text(emoji,
                                        style: const TextStyle(fontSize: 25)))),
                        ])),
                    Divider(height: 1, color: nec.separator),
                    action(CupertinoIcons.reply, 'Reply', MessageAction.reply),
                    action(
                        CupertinoIcons.pin,
                        message.pinnedAt == null
                            ? 'Pin Message'
                            : 'Unpin Message',
                        MessageAction.pin),
                    if (message.text.isNotEmpty)
                      action(CupertinoIcons.doc_on_doc, 'Copy Text',
                          MessageAction.copy),
                  ],
                  action(CupertinoIcons.trash, 'Delete Message',
                      MessageAction.delete,
                      destructive: true),
                  const SizedBox(height: 8),
                ]))),
          );
        });
