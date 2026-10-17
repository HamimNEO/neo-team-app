import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/storage/file_export.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class AgreementPdfViewer extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final String? base64Data;
  final String? url;

  const AgreementPdfViewer({
    super.key,
    required this.title,
    this.bytes,
    this.base64Data,
    this.url,
  });

  Uint8List? _resolveBytes() {
    if (bytes != null && bytes!.isNotEmpty) return bytes;
    if (base64Data != null && base64Data!.isNotEmpty) {
      try {
        final clean = base64Data!.contains(',')
            ? base64Data!.split(',').last
            : base64Data!;
        return base64Decode(clean);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _handleSave(BuildContext context, Uint8List rawBytes) async {
    try {
      final filename =
          title.toLowerCase().endsWith('.pdf') ? title : '$title.pdf';
      await FileExport.save(filename, rawBytes);
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Agreement saved to your device',
          type: NecToastType.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Unable to save agreement PDF. Please try again.',
          type: NecToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final resolvedBytes = _resolveBytes();

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.xmark, size: 20, color: nec.textPrimary),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: nec.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (resolvedBytes != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => _handleSave(context, resolvedBytes),
              child: Icon(
                CupertinoIcons.arrow_down_doc,
                size: 22,
                color: nec.brand,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: resolvedBytes != null
            ? PdfViewer.data(
                resolvedBytes,
                sourceName: title,
              )
            : (url != null && url!.isNotEmpty)
                ? PdfViewer.uri(
                    Uri.parse(url!),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: nec.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Agreement document is not available for preview.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: nec.textSecondary,
                              fontSize: 14,
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
