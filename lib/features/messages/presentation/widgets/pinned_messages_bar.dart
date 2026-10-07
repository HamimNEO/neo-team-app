import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/chat_message.dart';

class PinnedMessagesBar extends StatelessWidget {
  final List<ChatMessage> messages;
  final VoidCallback onTap;

  const PinnedMessagesBar(
      {super.key, required this.messages, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Material(
        color: nec.surface,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Icon(CupertinoIcons.pin_fill, color: nec.brand, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            messages.length == 1
                                ? 'Pinned message'
                                : '${messages.length} pinned messages',
                            style: TextStyle(
                                color: nec.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(messages.first.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: nec.textSecondary, fontSize: 13)),
                      ])),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_down,
                      color: nec.textTertiary, size: 14),
                ]))));
  }
}
