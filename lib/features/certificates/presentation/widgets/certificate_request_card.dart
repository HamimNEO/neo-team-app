import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/certificate_store.dart';
import '../../domain/models/certificate_request.dart';
import '../../services/certificate_pdf_service.dart';
import 'admin_fill_template_sheet.dart';
import 'certificate_status_badge.dart';

class CertificateRequestCard extends StatelessWidget {
  final CertificateRequest request;
  final bool isAdmin;

  const CertificateRequestCard({
    super.key,
    required this.request,
    this.isAdmin = false,
  });

  void _confirmReject(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reject Certificate Request'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Please provide a brief reason for rejecting this request:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Reason for rejection...',
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reject'),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await CertificateStore.instance
                    .rejectRequest(request.id, reason);
              } catch (error) {
                if (context.mounted) {
                  NecToast.show(context,
                      message: error is FormatException
                          ? error.message
                          : 'Unable to reject request.',
                      type: NecToastType.error);
                }
                return;
              }
              if (!context.mounted) return;
              NecToast.show(
                context,
                message: 'Certificate request rejected',
                type: NecToastType.info,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nec.separator.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: nec.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          request.type == CertificateType.testimonial
                              ? CupertinoIcons.quote_bubble_fill
                              : CupertinoIcons.doc_text_fill,
                          color: nec.brand,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.type.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ref: ${request.certificateNumber}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: nec.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CertificateStatusBadge(
                    status: request.status, apiStatus: request.apiStatus),
              ],
            ),
          ),
          Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAdmin) ...[
                  Row(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle,
                          size: 16, color: nec.brand),
                      const SizedBox(width: 6),
                      Text(
                        '${request.employeeName} (${request.employeeCode})',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: nec.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${request.employeeDesignation}',
                        style: TextStyle(
                          fontSize: 13,
                          color: nec.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purpose: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: nec.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        request.purpose,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: nec.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request.notes != null && request.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: nec.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          request.notes!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requested on ${request.requestDate}',
                      style: TextStyle(fontSize: 11.5, color: nec.textTertiary),
                    ),
                    if (request.deliveryDate != null)
                      Text(
                        'Delivered on ${request.deliveryDate}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
                if (request.isRejected &&
                    request.rejectionReason != null &&
                    request.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Rejection Note: ${request.rejectionReason}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (request.isDelivered) ...[
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      CertificatePdfService.downloadAndOpenCertificate(
                          context, request),
                  icon: const Icon(CupertinoIcons.doc_text_fill,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'View & Download Certificate (PDF)',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nec.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
          ] else if (isAdmin) ...[
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (request.isPending) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmReject(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await CertificateStore.instance
                                .acceptRequest(request.id);
                          } catch (error) {
                            if (context.mounted) {
                              NecToast.show(context,
                                  message: error is FormatException
                                      ? error.message
                                      : 'Unable to accept request.',
                                  type: NecToastType.error);
                            }
                            return;
                          }
                          if (!context.mounted) return;
                          NecToast.show(
                            context,
                            message:
                                'Request approved — Ready to prepare certificate',
                            type: NecToastType.success,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nec.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Accept Request',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ] else if (request.isInPreparation) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            AdminFillTemplateSheet.show(context, request),
                        icon: const Icon(
                            CupertinoIcons.pencil_ellipsis_rectangle,
                            size: 16,
                            color: Colors.white),
                        label: const Text('Fill Template & Deliver',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
