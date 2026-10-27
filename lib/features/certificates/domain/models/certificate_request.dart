import 'dart:typed_data';

enum CertificateType {
  workExperience('Work Experience Certificate',
      'Official confirmation of tenure, designation, and roles.'),
  testimonial('Testimonial & Recommendation',
      'Professional recommendation letter highlighting achievements and character.'),
  relieving('Relieving & Clearance Certificate',
      'Official clearance letter validating conclusion of employment duties.');

  final String title;
  final String subtitle;

  const CertificateType(this.title, this.subtitle);

  static CertificateType fromString(String? val) {
    if (val == null) return CertificateType.workExperience;
    for (final t in CertificateType.values) {
      if (t.name.toLowerCase() == val.toLowerCase() ||
          t.title.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return CertificateType.workExperience;
  }
}

enum CertificateStatus {
  pending('Pending Review', 'Submitted and awaiting admin evaluation'),
  inPreparation(
      'In Preparation', 'Approved by admin — document is being prepared'),
  delivered('Ready for Download', 'Issued and delivered to employee'),
  rejected('Rejected', 'Request could not be processed');

  final String label;
  final String description;

  const CertificateStatus(this.label, this.description);

  static CertificateStatus fromString(String? val) {
    if (val == null) return CertificateStatus.pending;
    for (final s in CertificateStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase() ||
          s.label.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return CertificateStatus.pending;
  }
}

class CertificateRequest {
  final String id;
  final String certificateNumber;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String employeeDesignation;
  final String employeeDepartment;
  final String? employeeAvatar;
  final String joinedDate;
  final String? leavingDate;
  final CertificateType type;
  final String purpose;
  final String? notes;
  final CertificateStatus status;
  final String requestDate;
  final String? reviewDate;
  final String? deliveryDate;
  final String? rejectionReason;
  final String conduct;
  final String keyContributions;
  final String authorizedSignatory;
  final String signatoryTitle;
  final Uint8List? generatedPdfBytes;
  final String? pdfUrl, apiStatus;

  const CertificateRequest({
    required this.id,
    required this.certificateNumber,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.employeeDesignation,
    required this.employeeDepartment,
    this.employeeAvatar,
    required this.joinedDate,
    this.leavingDate,
    required this.type,
    required this.purpose,
    this.notes,
    required this.status,
    required this.requestDate,
    this.reviewDate,
    this.deliveryDate,
    this.rejectionReason,
    this.conduct = '',
    this.keyContributions = '',
    this.authorizedSignatory = '',
    this.signatoryTitle = '',
    this.generatedPdfBytes,
    this.pdfUrl,
    this.apiStatus,
  });

  factory CertificateRequest.fromApi(Map<String, dynamic> data) {
    final employee = data['employee'] is Map ? data['employee'] as Map : {};
    final status = data['status']?.toString() ?? '';
    final fields =
        data['template_data'] is Map ? data['template_data'] as Map : data;
    String text(Object? value) => value?.toString() ?? '';
    if (data['id'] == null || data['status'] == null) {
      throw const FormatException(
          'The server returned an incomplete certificate.');
    }
    final department = employee['department'];
    return CertificateRequest(
        id: text(data['id']),
        certificateNumber: text(data['certificate_number']),
        employeeId: 'api_emp_${data['employee_id'] ?? employee['id']}',
        employeeName: text(employee['name'] ?? data['employee_name']),
        employeeCode: text(employee['employee_code']),
        employeeDesignation: text(employee['designation']),
        employeeDepartment:
            department is Map ? text(department['name']) : text(department),
        employeeAvatar: employee['photo_url']?.toString(),
        joinedDate: text(employee['joining_date'] ?? data['joining_date']),
        leavingDate: data['leaving_date']?.toString(),
        type: switch (data['type']) {
          'testimonial' => CertificateType.testimonial,
          'relieving' => CertificateType.relieving,
          _ => CertificateType.workExperience
        },
        purpose: text(data['purpose']),
        notes: data['notes']?.toString(),
        status: switch (status) {
          'in_preparation' ||
          'accepted' ||
          'approved' =>
            CertificateStatus.inPreparation,
          'delivered' => CertificateStatus.delivered,
          'rejected' => CertificateStatus.rejected,
          _ => CertificateStatus.pending
        },
        apiStatus: status,
        pdfUrl: data['pdf_url']?.toString(),
        requestDate: text(data['requested_at'] ?? data['created_at']),
        reviewDate: data['reviewed_at']?.toString(),
        deliveryDate: (data['delivered_at'] ?? data['issued_at'])?.toString(),
        rejectionReason:
            (data['rejection_reason'] ?? data['reason'])?.toString(),
        conduct: text(fields['conduct']),
        keyContributions: text(fields['key_contributions']),
        authorizedSignatory: text(fields['authorized_signatory_name']),
        signatoryTitle: text(fields['authorized_signatory_designation']));
  }

  bool get isPending => status == CertificateStatus.pending;

  bool get isInPreparation => status == CertificateStatus.inPreparation;

  bool get isDelivered => status == CertificateStatus.delivered;

  bool get isRejected => status == CertificateStatus.rejected;

  CertificateRequest copyWith({
    String? id,
    String? certificateNumber,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? employeeDesignation,
    String? employeeDepartment,
    String? employeeAvatar,
    String? joinedDate,
    String? leavingDate,
    CertificateType? type,
    String? purpose,
    String? notes,
    CertificateStatus? status,
    String? requestDate,
    String? reviewDate,
    String? deliveryDate,
    String? rejectionReason,
    String? conduct,
    String? keyContributions,
    String? authorizedSignatory,
    String? signatoryTitle,
    Uint8List? generatedPdfBytes,
  }) {
    return CertificateRequest(
      id: id ?? this.id,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeDesignation: employeeDesignation ?? this.employeeDesignation,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeeAvatar: employeeAvatar ?? this.employeeAvatar,
      joinedDate: joinedDate ?? this.joinedDate,
      leavingDate: leavingDate ?? this.leavingDate,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      reviewDate: reviewDate ?? this.reviewDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      conduct: conduct ?? this.conduct,
      keyContributions: keyContributions ?? this.keyContributions,
      authorizedSignatory: authorizedSignatory ?? this.authorizedSignatory,
      signatoryTitle: signatoryTitle ?? this.signatoryTitle,
      generatedPdfBytes: generatedPdfBytes ?? this.generatedPdfBytes,
      pdfUrl: pdfUrl,
      apiStatus: apiStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'certificateNumber': certificateNumber,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeCode': employeeCode,
        'employeeDesignation': employeeDesignation,
        'employeeDepartment': employeeDepartment,
        'employeeAvatar': employeeAvatar,
        'joinedDate': joinedDate,
        'leavingDate': leavingDate,
        'type': type.name,
        'purpose': purpose,
        'notes': notes,
        'status': status.name,
        'requestDate': requestDate,
        'reviewDate': reviewDate,
        'deliveryDate': deliveryDate,
        'rejectionReason': rejectionReason,
        'conduct': conduct,
        'keyContributions': keyContributions,
        'authorizedSignatory': authorizedSignatory,
        'signatoryTitle': signatoryTitle,
      };

  factory CertificateRequest.fromJson(Map<String, dynamic> json) =>
      CertificateRequest(
        id: json['id'] as String,
        certificateNumber:
            json['certificateNumber'] as String? ?? 'NEC-CERT-0001',
        employeeId: json['employeeId'] as String,
        employeeName: json['employeeName'] as String,
        employeeCode: json['employeeCode'] as String? ?? '',
        employeeDesignation: json['employeeDesignation'] as String? ?? '',
        employeeDepartment: json['employeeDepartment'] as String? ?? '',
        employeeAvatar: json['employeeAvatar'] as String?,
        joinedDate: json['joinedDate'] as String? ?? '2023-01-01',
        leavingDate: json['leavingDate'] as String?,
        type: CertificateType.fromString(json['type'] as String?),
        purpose: json['purpose'] as String? ?? 'New Employment',
        notes: json['notes'] as String?,
        status: CertificateStatus.fromString(json['status'] as String?),
        requestDate: json['requestDate'] as String? ?? '',
        reviewDate: json['reviewDate'] as String?,
        deliveryDate: json['deliveryDate'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        conduct: json['conduct'] as String? ??
            'During tenure, performance, conduct, and professional integrity were found to be exemplary.',
        keyContributions: json['keyContributions'] as String? ??
            'Demonstrated exceptional dedication, engineering leadership, and teamwork across high-impact platform initiatives.',
        authorizedSignatory:
            json['authorizedSignatory'] as String? ?? 'NAZMUL HASAN',
        signatoryTitle:
            json['signatoryTitle'] as String? ?? 'CEO & FOUNDER, NEONECY',
      );
}
