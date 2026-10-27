import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../auth/presentation/controllers/auth_session.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/storage/file_export.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../team/presentation/widgets/agreement_pdf_viewer.dart';
import '../domain/models/certificate_request.dart';

class CertificatePdfService {
  static const String companyName = 'NEONECY';
  static const String ceoAndFounder = 'NAZMUL HASAN';
  static const String companyTagline =
      'We Build Systems That Connect People With Possibilities';
  static const String companyDetails =
      'NEONECY builds digital products and public platforms that connect people, businesses, talent, knowledge, safety, and opportunities.';
  static const String officialWebsite = 'https://neonecy.com/';

  /// Generates high-fidelity formal Certificate PDF bytes.
  static Future<Uint8List> generateCertificatePdf(
      CertificateRequest request) async {
    final pdf = pw.Document(
      title: '${request.type.title} — ${request.employeeName}',
      author: companyName,
      creator: 'NEONECY Certificate Service',
    );

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logos/company_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    final brandColor = PdfColor.fromHex('#0066FF');
    final darkNavy = PdfColor.fromHex('#0F172A');
    final secondaryText = PdfColor.fromHex('#334155');
    final mutedText = PdfColor.fromHex('#64748B');
    final surfaceBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');
    final goldAccent = PdfColor.fromHex('#D97706');

    final issueDate = request.deliveryDate ??
        DateTime.now().toIso8601String().split('T').first;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: brandColor, width: 2),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 150,
                      height: 55,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: brandColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: surfaceBg,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: borderColor),
                        ),
                        child: pw.Text(
                          'CERTIFICATE NO: ${request.certificateNumber}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: brandColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Issue Date: $issueDate',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: secondaryText,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    companyTagline,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: darkNavy,
                    ),
                  ),
                  pw.Text(
                    officialWebsite,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(height: 1.5, color: brandColor),
              pw.SizedBox(height: 24),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: surfaceBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, width: 1),
                ),
                child: pw.Text(
                  request.type.title.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: darkNavy,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'TO WHOM IT MAY CONCERN',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: goldAccent,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.RichText(
                  textAlign: pw.TextAlign.justify,
                  text: pw.TextSpan(
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      color: darkNavy,
                      height: 1.6,
                    ),
                    children: [
                      const pw.TextSpan(
                          text: 'This is to officially certify that '),
                      pw.TextSpan(
                        text: request.employeeName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, color: brandColor),
                      ),
                      pw.TextSpan(
                          text:
                              ' (Employee ID: ${request.employeeCode}) was employed with '),
                      const pw.TextSpan(
                        text: '$companyName ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(text: 'in the capacity of '),
                      pw.TextSpan(
                        text: request.employeeDesignation,
                        style:
                            const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      const pw.TextSpan(text: ' within the '),
                      pw.TextSpan(
                        text: '${request.employeeDepartment} department',
                        style:
                            const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text:
                            ' from ${request.joinedDate} to ${request.leavingDate ?? "Present"}.',
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: surfaceBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONDUCT & PERFORMANCE EVALUATION',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      request.conduct,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: darkNavy,
                        height: 1.4,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'KEY CONTRIBUTIONS & RESPONSIBILITIES',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      request.keyContributions,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: darkNavy,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                child: pw.Text(
                  'We place on record our genuine appreciation for their dedication and valuable service during their association with NEONECY. We wish them all the best and continued success in all their future endeavors.',
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: secondaryText,
                    height: 1.5,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderColor),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: surfaceBg,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'OFFICIAL CORPORATE SEAL',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: mutedText,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Verified by NEONECY Human Resources',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: brandColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Portal: $officialWebsite',
                              style: const pw.TextStyle(fontSize: 7.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 190, height: 1.2, color: darkNavy),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        request.authorizedSignatory,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        request.signatoryTitle,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: secondaryText,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: borderColor, thickness: 0.6),
              pw.SizedBox(height: 4),
              pw.Text(
                'This document is computer-generated and issued by NEONECY Corporate Headquarters.',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Saves to phone files and opens the interactive viewer in-app.
  static Future<void> downloadAndOpenCertificate(
    BuildContext context,
    CertificateRequest request,
  ) async {
    try {
      NecToast.show(
        context,
        message: 'Preparing ${request.type.title}...',
        type: NecToastType.info,
      );

      final session = AuthSession.instance;
      final api = ApiClient(
          baseUrl: () => AppConfig.apiBaseUrl,
          accessToken: () => session.accessToken,
          onUnauthorized: session.invalidate);
      final Uint8List pdfBytes;
      if (request.isDelivered) {
        if (request.pdfUrl == null) {
          throw const FormatException(
              'The server has not supplied a certificate PDF URL.');
        }
        final token = session.accessToken;
        try {
          pdfBytes = await api.downloadDocument(request.pdfUrl!, token: token);
        } finally {
          api.close();
        }
        if (token != session.accessToken) {
          throw const FormatException('Your account changed.');
        }
      } else {
        api.close();
        pdfBytes = await generateCertificatePdf(request);
      }

      final safeName = request.employeeName
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName = '${safeName}_${request.type.name}_Certificate.pdf';

      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfBytes, flush: true);
      } catch (_) {}

      try {
        await FileExport.save(fileName, pdfBytes);
      } catch (_) {}

      if (!context.mounted) return;

      NecToast.show(
        context,
        message: 'Certificate downloaded and saved to your files!',
        type: NecToastType.success,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgreementPdfViewer(
            title: '${request.type.title} — ${request.employeeName}',
            bytes: pdfBytes,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Failed to open certificate: $e',
          type: NecToastType.error,
        );
      }
    }
  }
}
