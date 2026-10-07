import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

PreferredSizeWidget messagesAppBar(BuildContext context, String title,
    {Widget? titleWidget, List<Widget>? actions}) {
  final nec = Theme.of(context).extension<NecColors>()!;
  return AppBar(
    backgroundColor: nec.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leadingWidth: 86,
    leading: CupertinoButton(
      padding: const EdgeInsets.only(left: 10),
      onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(CupertinoIcons.back, size: 18, color: nec.brand),
        Text(' Back', style: TextStyle(color: nec.brand, fontSize: 16)),
      ]),
    ),
    centerTitle: titleWidget == null,
    titleSpacing: titleWidget == null ? 0 : 4,
    title: titleWidget ??
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: nec.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
    actions: actions,
    bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: nec.separator)),
  );
}

String messageDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday';
  }
  return DateFormat(date.year == now.year ? 'EEE, MMM d' : 'MMM d, yyyy')
      .format(date);
}

String messageListTime(DateTime date) => messageDay(date) == 'Today'
    ? DateFormat('h:mm a').format(date)
    : messageDay(date) == 'Yesterday'
        ? 'Yesterday'
        : DateFormat('MMM d').format(date);

class MessageEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MessageEmptyState(
      {super.key,
      required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Center(
        child: SingleChildScrollView(
            child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: nec.brand.withValues(alpha: .1), shape: BoxShape.circle),
            child:
                Icon(CupertinoIcons.chat_bubble_2, color: nec.brand, size: 36)),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: nec.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: nec.textSecondary, fontSize: 14, height: 1.5)),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 20),
          CupertinoButton.filled(
              onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    )));
  }
}
