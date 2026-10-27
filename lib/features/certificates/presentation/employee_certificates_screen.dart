import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/certificate_store.dart';
import 'widgets/certificate_request_card.dart';
import 'widgets/new_certificate_request_sheet.dart';

class EmployeeCertificatesScreen extends StatefulWidget {
  final String? employeeId;

  const EmployeeCertificatesScreen({super.key, this.employeeId});

  @override
  State<EmployeeCertificatesScreen> createState() =>
      _EmployeeCertificatesScreenState();
}

class _EmployeeCertificatesScreenState
    extends State<EmployeeCertificatesScreen> {
  @override
  void initState() {
    super.initState();
    CertificateStore.instance.load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final empId = widget.employeeId ?? DemoSession.instance.employeeId;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.surface,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 18, color: nec.brand),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: nec.brand,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 72,
        title: Text(
          'Certificates & Testimonials',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: nec.textPrimary,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () => CertificateStore.instance.load(force: true),
              icon: const Icon(CupertinoIcons.refresh),
              tooltip: 'Refresh certificates'),
          IconButton(
            icon: Icon(CupertinoIcons.plus_circle_fill,
                color: nec.brand, size: 24),
            tooltip: 'Request Certificate',
            onPressed: () =>
                NewCertificateRequestSheet.show(context, employeeId: empId),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: nec.separator.withValues(alpha: 0.3)),
        ),
      ),
      body: AnimatedBuilder(
        animation: CertificateStore.instance,
        builder: (context, _) {
          final requests = CertificateStore.instance.requestsForEmployee(empId);

          if (CertificateStore.instance.loading && requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (CertificateStore.instance.error != null && requests.isEmpty) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(CertificateStore.instance.error!),
              TextButton(
                  onPressed: () => CertificateStore.instance.load(force: true),
                  child: const Text('Retry'))
            ]));
          }
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: nec.brand.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.doc_checkmark,
                          color: nec.brand, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Certificate Requests Yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: nec.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Need an official Experience Certificate, Testimonial, or Relieving Letter? Submit a request to administration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: nec.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => NewCertificateRequestSheet.show(context,
                          employeeId: empId),
                      icon: const Icon(CupertinoIcons.plus,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Request New Certificate',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nec.brand,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return CertificateRequestCard(request: req, isAdmin: false);
            },
          );
        },
      ),
    );
  }
}
