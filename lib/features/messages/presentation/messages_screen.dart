import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_avatar.dart';
import '../../../core/widgets/nec_toast.dart';
import '../../team/data/employee_store.dart';
import '../data/message_store.dart';
import '../data/group_chat_store.dart';
import '../domain/models/group_chat.dart';
import '../domain/models/chat_message.dart';
import 'widgets/message_recipient_picker.dart';
import 'widgets/messages_ui.dart';
import 'widgets/group_chat_list.dart';

enum _MessageFilter { all, unread, archived }

enum _ChatCategory { direct, teams, departments }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = '';
  _MessageFilter _filter = _MessageFilter.all;
  _ChatCategory _category = _ChatCategory.direct;
  final _busyContacts = <String>{};
  bool _loading = true;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    Future.wait([MessageStore.instance.load(), GroupChatStore.instance.load()])
        .then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _compose() async {
    final employeeId = await chooseMessageRecipient(context);
    if (mounted && employeeId != null) {
      context.push('/messages/$employeeId');
    }
  }

  Future<void> _markAllRead() async {
    if (_markingRead) return;
    setState(() => _markingRead = true);
    try {
      if (_category == _ChatCategory.direct) {
        await MessageStore.instance
            .markRead(archivedOnly: _filter == _MessageFilter.archived);
      } else {
        await GroupChatStore.instance.markAllRead(_groupKind,
            archived: _filter == _MessageFilter.archived);
      }
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to mark messages as read. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  GroupChatKind get _groupKind => _category == _ChatCategory.teams
      ? GroupChatKind.team
      : GroupChatKind.department;

  Future<void> _conversationActions(MessageThread thread) async {
    final employee = EmployeeStore.instance.byId(thread.employeeId);
    if (employee == null || _busyContacts.contains(thread.employeeId)) return;
    final actor = DemoSession.instance.employeeId;
    final archived = MessageStore.instance.isArchived(thread.employeeId);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(employee.name),
        actions: [
          CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 'archive'),
              child: Text(archived ? 'Move to Inbox' : 'Archive Conversation')),
          CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Delete Conversation')),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ),
    );
    if (!mounted ||
        action == null ||
        DemoSession.instance.employeeId != actor) {
      return;
    }
    await _changeConversation(thread.employeeId,
        delete: action == 'delete', archived: !archived);
  }

  Future<void> _changeConversation(String employeeId,
      {required bool delete, bool? archived}) async {
    if (_busyContacts.contains(employeeId)) return;
    final actor = DemoSession.instance.employeeId;
    final name =
        EmployeeStore.instance.byId(employeeId)?.name ?? 'this employee';
    _busyContacts.add(employeeId);
    try {
      if (delete) {
        final confirmed = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: const Text('Delete Conversation?'),
                  content: Text(
                      'Remove your messages with $name from your view? Their conversation history will remain available to them.'),
                  actions: [
                    CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ));
        if (confirmed != true) return;
      }
      if (!mounted ||
          !DemoSession.instance.signedIn ||
          DemoSession.instance.employeeId != actor) {
        return;
      }
      if (delete) {
        await MessageStore.instance.deleteConversation(employeeId);
      } else {
        await MessageStore.instance
            .archiveConversation(employeeId, archived: archived ?? true);
      }
      if (mounted && DemoSession.instance.employeeId == actor) {
        NecToast.show(context,
            message: delete
                ? 'Conversation deleted'
                : archived == false
                    ? 'Moved to Inbox'
                    : 'Conversation archived');
      }
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to update this conversation. Please try again.',
            type: NecToastType.error);
      }
    } finally {
      _busyContacts.remove(employeeId);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([
          MessageStore.instance,
          GroupChatStore.instance,
          EmployeeStore.instance,
          DemoSession.instance
        ]),
        builder: (context, _) {
          final nec = Theme.of(context).extension<NecColors>()!;
          final store = MessageStore.instance;
          final archived = _filter == _MessageFilter.archived;
          final unreadOnly = _filter == _MessageFilter.unread;
          final groupStore = GroupChatStore.instance;
          final direct = _category == _ChatCategory.direct;
          final unreadCount = direct
              ? (archived ? store.archivedUnreadCount : store.unreadCount)
              : groupStore.list(_groupKind, archived: archived).fold<int>(
                  0, (sum, group) => sum + groupStore.unreadFor(group));
          final inboxUnread = direct
              ? store.unreadCount
              : groupStore.list(_groupKind).fold<int>(
                  0, (sum, group) => sum + groupStore.unreadFor(group));
          final archivedCount = direct
              ? store.archivedThreads.length
              : groupStore.list(_groupKind, archived: true).length;
          final query = _query.toLowerCase().trim();
          final threads = (archived ? store.archivedThreads : store.threads)
              .where((thread) {
            final employee = EmployeeStore.instance.byId(thread.employeeId)!;
            return (!unreadOnly || thread.unreadCount > 0) &&
                '${employee.name} ${employee.designation} ${thread.lastMessage.preview}'
                    .toLowerCase()
                    .contains(query);
          }).toList();

          final bottomInsets = MediaQuery.viewInsetsOf(context).bottom;

          return Scaffold(
            backgroundColor: nec.bg,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: nec.bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leadingWidth: 90,
              leading: CupertinoButton(
                padding: const EdgeInsets.only(left: 12),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.chevron_left,
                        color: Color(0xFF1677FF), size: 22),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF1677FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                'Messages',
                style: TextStyle(
                  color: nec.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                if (unreadCount > 0 && store.loadError == null)
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: _markingRead ? null : _markAllRead,
                    child: const Tooltip(
                      message: 'Mark all as read',
                      child: Icon(CupertinoIcons.checkmark_circle,
                          color: Color(0xFF1677FF), size: 22),
                    ),
                  ),
                if (direct)
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 16),
                    onPressed: _compose,
                    child: const Icon(
                      CupertinoIcons.square_pencil,
                      color: Color(0xFF1677FF),
                      size: 24,
                    ),
                  ),
              ],
            ),
            body: Stack(
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: _StayConnectedFooter(),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInsets),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: nec.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: nec.separator.withValues(alpha: 0.5)),
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              style: TextStyle(
                                  color: nec.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: direct
                                    ? 'Search messages or people...'
                                    : 'Search groups or messages...',
                                hintStyle: TextStyle(
                                    color: nec.textTertiary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400),
                                prefixIcon: Icon(CupertinoIcons.search,
                                    color: nec.textTertiary, size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ),
                        _buildCategoryTabBar(nec),
                        _buildFilterPills(nec, inboxUnread, archivedCount),
                        if (direct && store.loadError != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text(
                              store.loadError!,
                              style: const TextStyle(
                                  color: CupertinoColors.systemRed),
                            ),
                          ),
                        Expanded(
                          child: _loading
                              ? const Center(
                                  child: CupertinoActivityIndicator())
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await Future.wait([
                                      MessageStore.instance.syncRemote(),
                                      GroupChatStore.instance.syncRemote(),
                                    ]);
                                  },
                                  child: !direct
                                      ? GroupChatList(
                                          kind: _groupKind,
                                          query: _query,
                                          archived: archived,
                                          unreadOnly: unreadOnly,
                                        )
                                      : threads.isEmpty
                                          ? SingleChildScrollView(
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              child: MessageEmptyState(
                                                title: query.isNotEmpty
                                                    ? 'No matches found'
                                                    : archived
                                                        ? 'No archived conversations'
                                                        : unreadOnly
                                                            ? 'You’re all caught up'
                                                            : 'Your team, one message away',
                                                subtitle: query.isNotEmpty
                                                    ? 'Try another name or message.'
                                                    : archived
                                                        ? 'Archive a conversation by swiping right or holding it.'
                                                        : unreadOnly
                                                            ? 'New messages will appear here.'
                                                            : 'Start a conversation with any staff member or admin.',
                                                actionLabel: query.isEmpty &&
                                                        _filter ==
                                                            _MessageFilter.all
                                                    ? 'New Message'
                                                    : null,
                                                onAction: query.isEmpty &&
                                                        _filter ==
                                                            _MessageFilter.all
                                                    ? _compose
                                                    : null,
                                              ),
                                            )
                                          : ListView.separated(
                                              keyboardDismissBehavior:
                                                  ScrollViewKeyboardDismissBehavior
                                                      .onDrag,
                                              padding: const EdgeInsets.only(
                                                  bottom: 120),
                                              itemCount: threads.length,
                                              separatorBuilder:
                                                  (context, index) {
                                                return Divider(
                                                  height: 1,
                                                  indent: 82,
                                                  endIndent: 16,
                                                  color: nec.separator
                                                      .withValues(alpha: 0.5),
                                                );
                                              },
                                              itemBuilder: (context, index) {
                                                return _swipeableThread(
                                                    threads[index], nec);
                                              },
                                            ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildCategoryTabBar(NecColors nec) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: nec.separator.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _categoryTabItem(
              category: _ChatCategory.direct,
              icon: CupertinoIcons.chat_bubble_fill,
              label: 'Direct',
              nec: nec,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: nec.separator.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _categoryTabItem(
              category: _ChatCategory.teams,
              icon: Icons.groups_rounded,
              label: 'Teams',
              nec: nec,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: nec.separator.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _categoryTabItem(
              category: _ChatCategory.departments,
              icon: Icons.apartment_rounded,
              label: 'Departments',
              nec: nec,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTabItem({
    required _ChatCategory category,
    required IconData icon,
    required String label,
    required NecColors nec,
  }) {
    final isSelected = _category == category;
    const activeColor = Color(0xFF1677FF);
    final color = isSelected ? activeColor : const Color(0xFF6B7280);

    return InkWell(
      onTap: () => setState(() => _category = category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              height: 2.5,
              width: double.infinity,
              color: activeColor,
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }

  Widget _buildFilterPills(NecColors nec, int inboxUnread, int archivedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _pill(
            label: 'All',
            filter: _MessageFilter.all,
            nec: nec,
          ),
          const SizedBox(width: 10),
          _pill(
            label: 'Unread',
            filter: _MessageFilter.unread,
            count: inboxUnread,
            nec: nec,
          ),
          const SizedBox(width: 10),
          _pill(
            label: 'Archived',
            filter: _MessageFilter.archived,
            count: archivedCount,
            nec: nec,
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required _MessageFilter filter,
    int? count,
    required NecColors nec,
  }) {
    final isSelected = _filter == filter;
    const activeColor = Color(0xFF1677FF);
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          count != null && count > 0 && !isSelected ? '$label ($count)' : label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _swipeableThread(MessageThread thread, NecColors nec) {
    final archived = MessageStore.instance.isArchived(thread.employeeId);
    Widget background({required bool delete}) => Container(
        color: delete ? CupertinoColors.systemRed : const Color(0xFF1677FF),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: delete
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              delete
                  ? CupertinoIcons.trash
                  : archived
                      ? CupertinoIcons.tray_arrow_up
                      : CupertinoIcons.archivebox,
              color: Colors.white,
              size: 24),
          const SizedBox(height: 6),
          Text(
              delete
                  ? 'Delete'
                  : archived
                      ? 'Unarchive'
                      : 'Archive',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]));
    return Dismissible(
        key: ValueKey(
            '${DemoSession.instance.employeeId}_${thread.employeeId}_${_filter.name}'),
        background: background(delete: false),
        secondaryBackground: background(delete: true),
        confirmDismiss: (direction) async {
          await _changeConversation(thread.employeeId,
              delete: direction == DismissDirection.endToStart,
              archived: !archived);
          return false;
        },
        child: Material(
            color: Colors.transparent, child: _threadTile(thread, nec)));
  }

  Widget _threadTile(MessageThread thread, NecColors nec) {
    final employee = EmployeeStore.instance.byId(thread.employeeId)!;
    final last = thread.lastMessage;
    final mine = last.senderId == DemoSession.instance.employeeId;
    final unread = thread.unreadCount > 0;
    final isOnline = employee.status.toLowerCase() == 'active' ||
        employee.id == DemoSession.adminEmployeeId ||
        employee.name.contains('Test') ||
        employee.name.contains('Admin');

    return InkWell(
      onTap: () => context.push('/messages/${employee.id}'),
      onLongPress: () => _conversationActions(thread),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NecAvatar(
                  initials: employee.avatarInitials,
                  photoBase64: employee.photoBase64,
                  photoUrl: employee.photoUrl,
                  assetPath: employee.avatarAsset,
                  size: 52,
                ),
                Positioned(
                  right: 0,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    employee.designation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${mine ? 'You: ' : ''}${last.preview}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? nec.textPrimary : const Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  messageListTime(last.sentAt),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unread) ...[
                      Container(
                        constraints:
                            const BoxConstraints(minWidth: 19, minHeight: 19),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1677FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          thread.unreadCount > 99
                              ? '99+'
                              : '${thread.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: Color(0xFF9CA3AF),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StayConnectedFooter extends StatelessWidget {
  const _StayConnectedFooter();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      width: double.infinity,
      height: 180 + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FlightWavePainter(bottomPadding: bottomPadding),
            ),
          ),
          Positioned(
            bottom: 70 + bottomPadding,
            left: screenWidth * 0.46,
            child: Transform.rotate(
              angle: -0.22,
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF93C5FD),
                size: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 24 + bottomPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stay connected with your team',
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A718F),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 54,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightWavePainter extends CustomPainter {
  final double bottomPadding;

  _FlightWavePainter({this.bottomPadding = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE8F1FD).withValues(alpha: 0.45),
          const Color(0xFFF3F7FE).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    const baseH = 180.0;
    final wavePath = Path();
    wavePath.moveTo(0, baseH * 0.35);
    wavePath.quadraticBezierTo(
      size.width * 0.22,
      baseH * 0.05,
      size.width * 0.52,
      baseH * 0.3,
    );
    wavePath.quadraticBezierTo(
      size.width * 0.78,
      baseH * 0.52,
      size.width,
      baseH * 0.15,
    );
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    final trailPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final trailPath = Path();
    trailPath.moveTo(size.width * 0.04, baseH * 0.52);
    trailPath.cubicTo(
      size.width * 0.18,
      baseH * 0.38,
      size.width * 0.28,
      baseH * 0.62,
      size.width * 0.36,
      baseH * 0.50,
    );
    trailPath.cubicTo(
      size.width * 0.42,
      baseH * 0.32,
      size.width * 0.40,
      baseH * 0.52,
      size.width * 0.48,
      baseH * 0.36,
    );

    _drawDashedPath(canvas, trailPath, trailPaint, dashWidth: 4, dashGap: 4);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double dashGap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlightWavePainter oldDelegate) =>
      oldDelegate.bottomPadding != bottomPadding;
}
