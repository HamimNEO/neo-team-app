import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/storage/file_export.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../domain/models/employee.dart';
import '../presentation/widgets/agreement_pdf_viewer.dart';

class EmployeeReportPdfService {
  static const String companyName = 'NEONECY';
  static const String ceoAndFounder = 'NAZMUL HASAN';
  static const String companyTagline =
      'We Build Systems That Connect People With Possibilities';
  static const String companyDetails =
      'NEONECY builds digital products and public platforms that connect people, businesses, talent, knowledge, safety, and opportunities.';
  static const String officialWebsite = 'https://neonecy.com/';

  /// Generates the complete official Employee Details Report PDF bytes.
  static Future<Uint8List> generateReport(Employee employee) async {
    final pdf = pw.Document(
      title: '${employee.name} — Employee Details Report',
      author: companyName,
      creator: 'NEONECY Team Platform',
    );

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logos/company_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Fallback if logo fails to load
    }

    final brandColor = PdfColor.fromHex('#0066FF');
    final darkNavy = PdfColor.fromHex('#0F172A');
    final secondaryText = PdfColor.fromHex('#475569');
    final mutedText = PdfColor.fromHex('#64748B');
    final surfaceBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#CBD5E1');
    final greenColor = PdfColor.fromHex('#10B981');
    final amberColor = PdfColor.fromHex('#F59E0B');

    final isProbation = employee.isProbation;
    final now = DateTime.now();
    final generatedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 165,
                    height: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: brandColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: surfaceBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderColor, width: 1.2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'OFFICIAL EMPLOYEE RECORD',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        employee.displayCode,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: brandColor,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'Issued: $generatedDate',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: secondaryText,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  companyTagline,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: darkNavy,
                  ),
                ),
                pw.Text(
                  officialWebsite,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: brandColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              companyDetails,
              style: pw.TextStyle(
                  fontSize: 8.5, color: secondaryText, height: 1.3),
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 2, color: brandColor),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderColor, thickness: 0.8),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'NEONECY Platform · Website: $officialWebsite · Strictly Confidential',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: mutedText,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: mutedText,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: surfaceBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      employee.name,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${employee.designation} · ${employee.department} · ${employee.team}',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        color: secondaryText,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: isProbation
                        ? (employee.isProbationCompleted
                            ? greenColor
                            : amberColor)
                        : greenColor,
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Text(
                    isProbation
                        ? (employee.isProbationCompleted
                            ? 'PROBATION COMPLETED'
                            : 'PROBATION (${employee.probationRemainingDays}D LEFT)')
                        : 'PERMANENT EMPLOYEE',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _buildSectionHeader(
              '1. Organizational & Employment Details', brandColor),
          pw.SizedBox(height: 6),
          _buildDataTable([
            [
              'Employee Code',
              employee.displayCode,
              'Employment Status',
              employee.status
            ],
            [
              'Designation',
              employee.designation,
              'Department',
              employee.department.split(' · ').first
            ],
            [
              'Team',
              employee.team.isNotEmpty ? employee.team : '—',
              'System Role',
              employee.systemRole
            ],
            [
              'Reporting Manager',
              employee.reportsTo ?? 'Not assigned',
              'Joining Date',
              employee.joinedDate
            ],
            [
              'Employment Type',
              isProbation ? 'Probationary Period' : 'Permanent Confirmed',
              'Report Date',
              generatedDate,
            ],
          ]),
          pw.SizedBox(height: 12),
          if (isProbation) ...[
            _buildSectionHeader(
                '2. Probation Period Tracking & Schedule', amberColor),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: surfaceBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: amberColor, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Start: ${employee.probationStartDate ?? employee.joinedDate}',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      pw.Text(
                        'End: ${employee.probationEndDate ?? '—'}',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkNavy,
                        ),
                      ),
                      pw.Text(
                        'Progress: ${(employee.probationProgress * 100).toInt()}% (${employee.probationElapsedDays} / ${employee.probationTotalDays} days)',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: amberColor,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Stack(
                    children: [
                      pw.Container(
                        height: 7,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          color: borderColor,
                          borderRadius: pw.BorderRadius.circular(3.5),
                        ),
                      ),
                      pw.Container(
                        height: 7,
                        width:
                            480 * employee.probationProgress.clamp(0.02, 1.0),
                        decoration: pw.BoxDecoration(
                          color: employee.isProbationCompleted
                              ? greenColor
                              : amberColor,
                          borderRadius: pw.BorderRadius.circular(3.5),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    employee.isProbationCompleted
                        ? 'Probation concluded. Eligible for administrative promotion to Permanent employment.'
                        : 'Trial period active. Status will be eligible for permanent promotion on concluding date.',
                    style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          _buildSectionHeader(
            isProbation
                ? '3. Contact & Personal Profile'
                : '2. Contact & Personal Profile',
            brandColor,
          ),
          pw.SizedBox(height: 6),
          _buildDataTable([
            [
              'Work Email',
              employee.email.isNotEmpty ? employee.email : '—',
              'Phone',
              employee.phone.isNotEmpty ? employee.phone : '—'
            ],
            [
              'Date of Birth',
              employee.dateOfBirth.isNotEmpty ? employee.dateOfBirth : '—',
              'Emergency Contact',
              employee.emergencyContactName.isNotEmpty
                  ? employee.emergencyContactName
                  : '—'
            ],
            [
              'Emergency Phone',
              employee.emergencyContactPhone.isNotEmpty
                  ? employee.emergencyContactPhone
                  : '—',
              'Residential Address',
              employee.address.isNotEmpty ? employee.address : '—'
            ],
          ]),
          pw.SizedBox(height: 12),
          _buildSectionHeader(
            isProbation
                ? '4. Compensation & Contract Verification'
                : '3. Compensation & Contract Verification',
            brandColor,
          ),
          pw.SizedBox(height: 6),
          _buildDataTable([
            [
              'Basic Salary',
              employee.salary != null
                  ? '${employee.salary!.currency} ${employee.salary!.basic}'
                  : '—',
              'Gross Pay',
              employee.salary != null
                  ? '${employee.salary!.currency} ${employee.salary!.gross}'
                  : '—',
            ],
            [
              'Take Home (Net)',
              employee.salary != null
                  ? '${employee.salary!.currency} ${employee.salary!.net}'
                  : '—',
              'Pay Frequency',
              employee.salary != null ? employee.salary!.frequency : 'Monthly',
            ],
            [
              'Agreement Document',
              employee.hasAgreementPdf
                  ? (employee.agreementPdfName ?? 'Attached Contract (PDF)')
                  : 'Official Standard Appointment Contract',
              'Company Meals Co-Pay',
              employee.isMealFree
                  ? '100% Free'
                  : '${employee.mealCoPayPercent}% employee share',
            ],
          ]),
          pw.SizedBox(height: 20),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
              color: surfaceBg,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AUTHORIZED COMPANY SIGNATURE',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.SizedBox(height: 38),
                    pw.Container(width: 200, height: 1.2, color: darkNavy),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      ceoAndFounder,
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'CEO & FOUNDER, $companyName',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: secondaryText,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'EMPLOYEE ACKNOWLEDGMENT',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                    pw.SizedBox(height: 38),
                    pw.Container(width: 200, height: 1.2, color: darkNavy),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      employee.name,
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Employee Acceptance Signature',
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
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Downloads, saves to device files, and immediately previews the report in-app.
  static Future<void> downloadAndOpenReport(
    BuildContext context,
    Employee employee,
  ) async {
    try {
      NecToast.show(
        context,
        message: 'Generating employee details report...',
        type: NecToastType.info,
      );

      final pdfBytes = await generateReport(employee);

      final safeName = employee.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final fileName = '${safeName}_Details_Report.pdf';

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
        message: 'Report downloaded & saved to your device files!',
        type: NecToastType.success,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgreementPdfViewer(
            title: '${employee.name} — Employee Details Report',
            bytes: pdfBytes,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        NecToast.show(
          context,
          message: 'Failed to generate report: $e',
          type: NecToastType.error,
        );
      }
    }
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// Builds a perfectly aligned 4-column data table.
  /// Column 0: Label 1 (Fixed 115pt, grey bold)
  /// Column 1: Value 1 (Flex 1, dark navy bold)
  /// Column 2: Label 2 (Fixed 115pt, grey bold)
  /// Column 3: Value 2 (Flex 1, dark navy bold)
  static pw.Widget _buildDataTable(List<List<String>> rows) {
    final borderColor = PdfColor.fromHex('#CBD5E1');
    final labelColor = PdfColor.fromHex('#475569');
    final valueColor = PdfColor.fromHex('#0F172A');
    final rowBg = PdfColor.fromHex('#F8FAFC');

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(115),
        1: pw.FlexColumnWidth(1),
        2: pw.FixedColumnWidth(115),
        3: pw.FlexColumnWidth(1),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final bg = index.isEven ? rowBg : PdfColors.white;

        return pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 9,
                  color: labelColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: valueColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
              child: pw.Text(
                row[2],
                style: pw.TextStyle(
                  fontSize: 9,
                  color: labelColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
              child: pw.Text(
                row[3],
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: valueColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
