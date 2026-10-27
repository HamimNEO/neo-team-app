import 'package:file_picker/file_picker.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/certificate_store.dart';
import '../../domain/models/certificate_request.dart';
import '../../services/certificate_pdf_service.dart';

class AdminFillTemplateSheet extends StatefulWidget {
  final CertificateRequest request;

  const AdminFillTemplateSheet({super.key, required this.request});

  static Future<bool?> show(BuildContext context, CertificateRequest request) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminFillTemplateSheet(request: request),
    );
  }

  @override
  State<AdminFillTemplateSheet> createState() => _AdminFillTemplateSheetState();
}

class _AdminFillTemplateSheetState extends State<AdminFillTemplateSheet> {
  late final TextEditingController _conductController;
  late final TextEditingController _contributionsController;
  late final TextEditingController _signatoryController;
  late final TextEditingController _titleController;
  late final TextEditingController _leavingDateController;
  bool _saving = false;
  late final _numberController =
      TextEditingController(text: widget.request.certificateNumber);
  ApiUpload? _seal, _signature;

  Future<void> _pickOfficialImage(bool seal) async {
    try {
      final selected = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg'],
          withData: true);
      if (selected == null || !mounted) return;
      final file = selected.files.single;
      if (file.bytes == null ||
          file.bytes!.isEmpty ||
          file.size > 10 * 1024 * 1024) {
        throw const FormatException('Select a PNG or JPEG up to 10 MB.');
      }
      setState(() {
        final upload = ApiUpload(
            field: seal ? 'official_seal' : 'signature',
            bytes: file.bytes!,
            filename: file.name,
            mimeType: file.extension == 'png' ? 'image/png' : 'image/jpeg');
        if (seal) {
          _seal = upload;
        } else {
          _signature = upload;
        }
      });
    } catch (e) {
      if (mounted) {
        NecToast.show(context,
            message: e is FormatException
                ? e.message
                : 'The image could not be selected.',
            type: NecToastType.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _conductController = TextEditingController(text: widget.request.conduct);
    _contributionsController =
        TextEditingController(text: widget.request.keyContributions);
    _signatoryController =
        TextEditingController(text: widget.request.authorizedSignatory);
    _titleController =
        TextEditingController(text: widget.request.signatoryTitle);
    _leavingDateController = TextEditingController(
      text: widget.request.leavingDate ?? 'Present',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _conductController.dispose();
    _contributionsController.dispose();
    _signatoryController.dispose();
    _titleController.dispose();
    _leavingDateController.dispose();
    super.dispose();
  }

  CertificateRequest _buildPreviewRequest() {
    return widget.request.copyWith(
      conduct: _conductController.text.trim(),
      keyContributions: _contributionsController.text.trim(),
      authorizedSignatory: _signatoryController.text.trim(),
      signatoryTitle: _titleController.text.trim(),
      leavingDate: _leavingDateController.text.trim().isNotEmpty
          ? _leavingDateController.text.trim()
          : 'Present',
      deliveryDate: DateTime.now().toIso8601String().split('T').first,
    );
  }

  Future<void> _handlePreview() async {
    final preview = _buildPreviewRequest();
    await CertificatePdfService.downloadAndOpenCertificate(context, preview);
  }

  Future<void> _handleDeliver() async {
    setState(() => _saving = true);

    try {
      await CertificateStore.instance.deliverCertificate(
        widget.request.id,
        certificateNumber: _numberController.text.trim(),
        officialSeal: _seal,
        signature: _signature,
        conduct: _conductController.text.trim(),
        keyContributions: _contributionsController.text.trim(),
        leavingDate: _leavingDateController.text.trim().isNotEmpty
            ? _leavingDateController.text.trim()
            : 'Present',
        authorizedSignatory: _signatoryController.text.trim(),
        signatoryTitle: _titleController.text.trim(),
      );

      if (!mounted) return;

      NecToast.show(
        context,
        message:
            'Certificate successfully delivered to ${widget.request.employeeName}!',
        type: NecToastType.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        NecToast.show(
          context,
          message: 'Failed to deliver certificate: $e',
          type: NecToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fill & Issue Certificate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: nec.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'For ${widget.request.employeeName} (${widget.request.employeeCode})',
                            style: TextStyle(
                              fontSize: 13,
                              color: nec.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 18),
                      color: nec.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                          labelText: 'Certificate number')),
                  Wrap(spacing: 12, children: [
                    TextButton.icon(
                        onPressed:
                            _saving ? null : () => _pickOfficialImage(true),
                        icon: const Icon(CupertinoIcons.checkmark_seal),
                        label: Text(_seal?.filename ?? 'Upload official seal')),
                    TextButton.icon(
                        onPressed:
                            _saving ? null : () => _pickOfficialImage(false),
                        icon: const Icon(CupertinoIcons.signature),
                        label:
                            Text(_signature?.filename ?? 'Upload signature')),
                  ]),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: nec.separator),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: nec.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(CupertinoIcons.doc_checkmark_fill,
                              color: nec.brand, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.request.type.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: nec.textPrimary,
                                ),
                              ),
                              Text(
                                'Purpose: ${widget.request.purpose}',
                                style: TextStyle(
                                    fontSize: 12, color: nec.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('JOINING DATE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: nec.textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: nec.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: nec.separator),
                              ),
                              child: Text(widget.request.joinedDate,
                                  style: TextStyle(
                                      fontSize: 13.5, color: nec.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RELIEVING / END DATE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: nec.textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _leavingDateController,
                              style: TextStyle(
                                  fontSize: 13.5, color: nec.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Present or 2026-10-30',
                                filled: true,
                                fillColor: nec.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: nec.separator),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CONDUCT & PERFORMANCE EVALUATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: nec.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _conductController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13.5, color: nec.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: nec.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KEY CONTRIBUTIONS & ACHIEVEMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: nec.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _contributionsController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13.5, color: nec.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: nec.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: nec.separator),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AUTHORIZED SIGNATORY',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: nec.textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _signatoryController,
                              style: TextStyle(
                                  fontSize: 13.5, color: nec.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: nec.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: nec.separator),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SIGNATORY TITLE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: nec.textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _titleController,
                              style: TextStyle(
                                  fontSize: 13.5, color: nec.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: nec.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: nec.separator),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: nec.surface,
              border: Border(
                top: BorderSide(color: nec.separator.withValues(alpha: 0.4)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handlePreview,
                      icon:
                          Icon(CupertinoIcons.eye, size: 16, color: nec.brand),
                      label: Text('Preview PDF',
                          style: TextStyle(
                              color: nec.brand, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: nec.brand),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _handleDeliver,
                      icon: _saving
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : const Icon(CupertinoIcons.paperplane_fill,
                              size: 16, color: Colors.white),
                      label: Text(
                        _saving ? 'Delivering...' : 'Deliver to Employee',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nec.brand,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
  }
}
