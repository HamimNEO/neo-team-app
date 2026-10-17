import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';
import '../domain/models/certificate_request.dart';

class CertificateStore extends ChangeNotifier {
  static final CertificateStore instance = CertificateStore._();

  CertificateStore._() {
    _seedInitialData();
  }

  final List<CertificateRequest> _requests = [];

  List<CertificateRequest> get allRequests => List.unmodifiable(_requests);

  List<CertificateRequest> requestsForEmployee(String employeeId) {
    return _requests.where((r) => r.employeeId == employeeId).toList();
  }

  int get pendingCount =>
      _requests.where((r) => r.status == CertificateStatus.pending).length;

  int get inPreparationCount => _requests
      .where((r) => r.status == CertificateStatus.inPreparation)
      .length;

  CertificateRequest? byId(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void _seedInitialData() {
    _requests.addAll([
      const CertificateRequest(
        id: 'cert_req_001',
        certificateNumber: 'NEC-EXP-2026-0081',
        employeeId: 'emp_002',
        employeeName: 'Yeapas',
        employeeCode: 'NEC-MGR-002',
        employeeDesignation: 'Manager',
        employeeDepartment: 'Software Engineering',
        joinedDate: '2022-01-15',
        type: CertificateType.workExperience,
        purpose: 'Career Development & External Opportunities',
        notes:
            'Requesting official work experience certificate for senior technical lead evaluation.',
        status: CertificateStatus.pending,
        requestDate: '2026-10-15',
      ),
      const CertificateRequest(
        id: 'cert_req_002',
        certificateNumber: 'NEC-TST-2026-0075',
        employeeId: 'emp_002',
        employeeName: 'Yeapas',
        employeeCode: 'NEC-MGR-002',
        employeeDesignation: 'Manager',
        employeeDepartment: 'Software Engineering',
        joinedDate: '2022-01-15',
        type: CertificateType.testimonial,
        purpose: 'Higher Studies & Master’s Program Admission',
        notes:
            'Please highlight leadership and software engineering track record.',
        status: CertificateStatus.delivered,
        requestDate: '2026-10-01',
        reviewDate: '2026-10-02',
        deliveryDate: '2026-10-03',
        conduct:
            'Yeapas has consistently exhibited highest-tier technical ingenuity, unwavering work ethic, and sterling character.',
        keyContributions:
            'Spearheaded critical system architecture, led team operational sprints, and fostered cross-functional excellence.',
        authorizedSignatory: 'NAZMUL HASAN',
        signatoryTitle: 'CEO & FOUNDER, NEONECY',
      ),
    ]);
  }

  /// Employee submits a new request
  Future<CertificateRequest> submitRequest({
    required String employeeId,
    required String employeeName,
    required String employeeCode,
    required String employeeDesignation,
    required String employeeDepartment,
    required String joinedDate,
    required CertificateType type,
    required String purpose,
    String? notes,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final numberSeq = (_requests.length + 82).toString().padLeft(4, '0');
    final certNumber = type == CertificateType.testimonial
        ? 'NEC-TST-${now.year}-$numberSeq'
        : 'NEC-EXP-${now.year}-$numberSeq';

    final request = CertificateRequest(
      id: 'cert_req_${DateTime.now().millisecondsSinceEpoch}',
      certificateNumber: certNumber,
      employeeId: employeeId,
      employeeName: employeeName,
      employeeCode: employeeCode,
      employeeDesignation: employeeDesignation,
      employeeDepartment: employeeDepartment,
      joinedDate: joinedDate,
      type: type,
      purpose: purpose,
      notes: notes,
      status: CertificateStatus.pending,
      requestDate: dateStr,
    );

    _requests.insert(0, request);
    notifyListeners();

    try {
      await NotificationService.instance.showCustomNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'New Certificate Request',
        body: '$employeeName requested a ${type.title} for $purpose.',
        payload: jsonEncode({
          'type': 'work',
          'screen': '/certificates/admin',
        }),
      );
    } catch (_) {}

    return request;
  }

  /// Admin accepts request -> moves to In Preparation / Pending Delivery
  void acceptRequest(String id) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updated = _requests[index].copyWith(
      status: CertificateStatus.inPreparation,
      reviewDate: dateStr,
    );

    _requests[index] = updated;
    notifyListeners();

    try {
      NotificationService.instance.showCustomNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Certificate Request Approved',
        body:
            'Admin approved your ${updated.type.title} request. The document is being prepared.',
        payload: jsonEncode({
          'type': 'work',
          'screen': '/certificates/my',
        }),
      );
    } catch (_) {}
  }

  /// Admin rejects request with reason
  void rejectRequest(String id, String reason) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updated = _requests[index].copyWith(
      status: CertificateStatus.rejected,
      reviewDate: dateStr,
      rejectionReason: reason,
    );

    _requests[index] = updated;
    notifyListeners();

    try {
      NotificationService.instance.showCustomNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Certificate Request Update',
        body:
            'Your ${updated.type.title} request could not be approved: $reason',
        payload: jsonEncode({
          'type': 'work',
          'screen': '/certificates/my',
        }),
      );
    } catch (_) {}
  }

  /// Admin fills template and delivers certificate to employee
  void deliverCertificate(
    String id, {
    required String conduct,
    required String keyContributions,
    String? leavingDate,
    required String authorizedSignatory,
    required String signatoryTitle,
  }) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updated = _requests[index].copyWith(
      status: CertificateStatus.delivered,
      deliveryDate: dateStr,
      leavingDate: leavingDate,
      conduct: conduct,
      keyContributions: keyContributions,
      authorizedSignatory: authorizedSignatory,
      signatoryTitle: signatoryTitle,
    );

    _requests[index] = updated;
    notifyListeners();

    try {
      NotificationService.instance.showCustomNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Certificate Ready for Download! 📄',
        body:
            'Your official ${updated.type.title} has been signed by $authorizedSignatory and is ready to view & download.',
        payload: jsonEncode({
          'type': 'work',
          'screen': '/certificates/my',
        }),
      );
    } catch (_) {}
  }
}
