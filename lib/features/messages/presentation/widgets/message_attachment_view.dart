import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/attachment_storage.dart';
import '../../data/chat_attachment_picker.dart';
import '../../domain/models/chat_attachment.dart';

class MessageAttachmentView extends StatefulWidget {
  final ChatAttachment attachment;
  final bool mine;

  const MessageAttachmentView(
      {super.key, required this.attachment, required this.mine});

  @override
  State<MessageAttachmentView> createState() => _MessageAttachmentViewState();
}

class _MessageAttachmentViewState extends State<MessageAttachmentView> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage) {
      _bytes = AttachmentStorage.read(widget.attachment);
    }
  }

  @override
  void didUpdateWidget(covariant MessageAttachmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id ||
        oldWidget.attachment.isImage != widget.attachment.isImage) {
      _bytes = widget.attachment.isImage
          ? AttachmentStorage.read(widget.attachment)
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final attachment = widget.attachment;
    final color = widget.mine ? Colors.white : nec.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
          onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _AttachmentPreview(attachment: attachment)),
          child: attachment.isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      height: 180,
                      width: 260,
                      child: FutureBuilder<Uint8List>(
                          future: _bytes,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child:
                                      Icon(CupertinoIcons.photo, color: color));
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CupertinoActivityIndicator());
                            }
                            return Image.memory(snapshot.data!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Center(
                                    child: Icon(CupertinoIcons.photo,
                                        color: color)));
                          })))
              : Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: widget.mine
                          ? Colors.white.withValues(alpha: .12)
                          : nec.bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(CupertinoIcons.doc_fill, color: color, size: 28),
                    const SizedBox(width: 10),
                    Flexible(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(attachment.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(attachment.sizeLabel,
                              style: TextStyle(
                                  color: color.withValues(alpha: .7),
                                  fontSize: 11)),
                        ])),
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.arrow_down_to_line,
                        size: 18, color: color),
                  ]))),
    );
  }
}

class _AttachmentPreview extends StatefulWidget {
  final ChatAttachment attachment;

  const _AttachmentPreview({required this.attachment});

  @override
  State<_AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<_AttachmentPreview> {
  late final Future<Uint8List> _bytes =
      AttachmentStorage.read(widget.attachment);
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await ChatAttachmentPicker.export(widget.attachment);
      if (mounted && saved) NecToast.show(context, message: 'Attachment saved');
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Unable to save this attachment.',
            type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final attachment = widget.attachment;
    return Dialog.fullscreen(
        backgroundColor: nec.bg,
        child: Scaffold(
          backgroundColor: nec.bg,
          appBar: AppBar(
              backgroundColor: nec.bg,
              elevation: 0,
              leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(CupertinoIcons.xmark, color: nec.brand)),
              title: Text(attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: nec.textPrimary, fontSize: 16)),
              actions: [
                CupertinoButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CupertinoActivityIndicator()
                        : Icon(CupertinoIcons.arrow_down_to_line,
                            color: nec.brand))
              ]),
          body: SafeArea(
              child: FutureBuilder<Uint8List>(
                  future: _bytes,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('This attachment is no longer available.',
                              style: TextStyle(color: nec.textSecondary)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (attachment.isImage) {
                      return Center(
                          child: InteractiveViewer(
                              minScale: .5,
                              maxScale: 5,
                              child: Image.memory(snapshot.data!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                          'Image preview unavailable. Use Save to keep the file.',
                                          style: TextStyle(
                                              color: nec.textSecondary))))));
                    }
                    final extension =
                        attachment.name.split('.').last.toLowerCase();
                    if (['txt', 'md', 'csv', 'json', 'log']
                        .contains(extension)) {
                      final bytes = snapshot.data!;
                      final text = utf8.decode(
                          bytes.length > 100000
                              ? bytes.sublist(0, 100000)
                              : bytes,
                          allowMalformed: true);
                      return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: SelectableText(
                              '$text${bytes.length > 100000 ? '\n\nPreview truncated. Save to read the complete file.' : ''}',
                              style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 14,
                                  height: 1.5)));
                    }
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.doc_fill,
                                      color: nec.brand, size: 64),
                                  const SizedBox(height: 20),
                                  Text(attachment.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: nec.textPrimary,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text(attachment.sizeLabel,
                                      style:
                                          TextStyle(color: nec.textSecondary)),
                                  const SizedBox(height: 24),
                                  CupertinoButton.filled(
                                      onPressed: _saving ? null : _save,
                                      child: const Text('Save File')),
                                ])));
                  })),
        ));
  }
}
