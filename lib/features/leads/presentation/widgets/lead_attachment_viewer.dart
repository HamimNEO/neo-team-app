import 'dart:convert';
import 'dart:typed_data';
import '../../../../core/storage/file_export.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../auth/presentation/controllers/auth_session.dart';
import '../../data/lead_store.dart';

class LeadAttachmentViewer extends StatefulWidget {
  const LeadAttachmentViewer(
      {super.key,
      required this.leadId,
      required this.attachmentId,
      required this.filename,
      required this.mimeType});

  final String leadId, attachmentId, filename, mimeType;

  @override
  State<LeadAttachmentViewer> createState() => _LeadAttachmentViewerState();
}

class _LeadAttachmentViewerState extends State<LeadAttachmentViewer> {
  late Future<Uint8List> _download;
  late final String? _token;

  @override
  void initState() {
    super.initState();
    _token = AuthSession.instance.accessToken;
    AuthSession.instance.addListener(_sessionChanged);
    _download = _fetch();
  }

  Future<Uint8List> _fetch() =>
      LeadStore.instance.downloadAttachment(widget.leadId, widget.attachmentId);

  void _sessionChanged() {
    if (mounted && AuthSession.instance.accessToken != _token) setState(() {});
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_sessionChanged);
    super.dispose();
  }

  Future<void> _save(Uint8List bytes) async {
    try {
      await FileExport.save(widget.filename, bytes);
    } catch (_) {
      if (mounted) {
        NecToast.show(context,
            message: 'Could not save this attachment. Please try again.',
            type: NecToastType.error);
      }
    }
  }

  Widget _preview(Uint8List bytes) {
    final ext = widget.filename.split('.').last.toLowerCase();
    if (widget.mimeType == 'application/pdf' || ext == 'pdf') {
      return PdfViewer.data(bytes,
          sourceName:
              '${widget.leadId}/${widget.attachmentId}/${widget.filename}');
    }
    if (widget.mimeType.startsWith('image/') ||
        ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext)) {
      return Center(
          child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.memory(bytes,
                  errorBuilder: (_, __, ___) =>
                      const Text('This image could not be displayed.'))));
    }
    if (widget.mimeType.startsWith('text/') ||
        ['txt', 'csv', 'json', 'md', 'log'].contains(ext)) {
      final text =
          utf8.decode(bytes.take(100000).toList(), allowMalformed: true);
      return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
              '$text${bytes.length > 100000 ? '\n\nPreview truncated. Save to view the full file.' : ''}'));
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.insert_drive_file_outlined, size: 56),
              const SizedBox(height: 16),
              const Text('Save this attachment to open it in a compatible app.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: () => _save(bytes),
                  icon: const Icon(Icons.download),
                  label: const Text('Save file')),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    if (AuthSession.instance.accessToken != _token) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }
    return FutureBuilder<Uint8List>(
        future: _download,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          return Scaffold(
            appBar: AppBar(
                title: Text(widget.filename,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  if (bytes != null)
                    IconButton(
                        tooltip: 'Save file',
                        onPressed: () => _save(bytes),
                        icon: const Icon(Icons.download_outlined)),
                ]),
            body: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      snapshot.error is ApiException
                                          ? (snapshot.error as ApiException)
                                              .message
                                          : 'Could not load this attachment.',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: () =>
                                          setState(() => _download = _fetch()),
                                      child: const Text('Retry')),
                                ])))
                    : _preview(bytes!),
          );
        });
  }
}
