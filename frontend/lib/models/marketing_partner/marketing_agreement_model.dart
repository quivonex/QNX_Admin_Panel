// lib/models/marketing_partner/marketing_agreement_model.dart

import 'dart:typed_data';

// ============================================================
// ✅ MARKETING PARTNER AGREEMENT DATA MODEL
// ============================================================
class MarketingPartnerAgreementData {
  final int agreementId;
  final String agreementNumber;
  final int marketingPartnerId;
  final String? marketingPartnerName;
  final String agreementRole;
  final String agreementStartDate;
  final String agreementEndDate;
  final String? marketingPartnerAddress;
  final String companyCommissionPercentage;
  final String profitSharePercentage;
  final String sellingCommissionPercentage;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String? remarks;
  final String? adharNumber;
  final String? panNumber;

  final String? qnxMartSignUrl;
  final String? qnxMartSignS3Key;
  final String? marketingPartnerSignUrl;
  final String? marketingPartnerSignS3Key;
  final String? qnxMartPictureUrl;
  final String? qnxMartPictureS3Key;
  final String? marketingPartnerPictureUrl;
  final String? marketingPartnerPictureS3Key;

  // ✅ PDF
  final String? uploadedAgreementPdfUrl;
  final String? uploadedAgreementPdfS3Key;

  final String status;
  final String agreementStage;
  final int? createdBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? partnerSignedAt;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;

  MarketingPartnerAgreementData({
    required this.agreementId,
    required this.agreementNumber,
    required this.marketingPartnerId,
    this.marketingPartnerName,
    required this.agreementRole,
    required this.agreementStartDate,
    required this.agreementEndDate,
    this.marketingPartnerAddress,
    required this.companyCommissionPercentage,
    required this.profitSharePercentage,
    required this.sellingCommissionPercentage,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    this.remarks,
    this.adharNumber,
    this.panNumber,
    this.qnxMartSignUrl,
    this.qnxMartSignS3Key,
    this.marketingPartnerSignUrl,
    this.marketingPartnerSignS3Key,
    this.qnxMartPictureUrl,
    this.qnxMartPictureS3Key,
    this.marketingPartnerPictureUrl,
    this.marketingPartnerPictureS3Key,
    this.uploadedAgreementPdfUrl,
    this.uploadedAgreementPdfS3Key,
    required this.status,
    required this.agreementStage,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.partnerSignedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketingPartnerAgreementData.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerAgreementData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartnerName: json['marketing_partner_name']?.toString(),
      agreementRole: json['agreement_role'] ?? 'marketing_partner',
      agreementStartDate: json['agreement_start_date'] ?? '',
      agreementEndDate: json['agreement_end_date'] ?? '',
      marketingPartnerAddress: json['marketing_partner_address']?.toString(),
      companyCommissionPercentage:
      json['company_commission_percentage']?.toString() ?? '0',
      profitSharePercentage:
      json['profit_share_percentage']?.toString() ?? '0',
      sellingCommissionPercentage:
      json['selling_commission_percentage']?.toString() ?? '0',
      additionalPoints: json['additional_points'] ?? '',
      qnxMartRepresentative: json['qnx_mart_representative'] ?? '',
      remarks: json['remarks']?.toString(),
      adharNumber: json['adhar_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      qnxMartSignUrl: json['qnx_mart_sign_url']?.toString(),
      qnxMartSignS3Key: json['qnx_mart_sign_s3_key']?.toString(),
      marketingPartnerSignUrl: json['marketing_partner_sign_url']?.toString(),
      marketingPartnerSignS3Key:
      json['marketing_partner_sign_s3_key']?.toString(),
      qnxMartPictureUrl: json['qnx_mart_picture_url']?.toString(),
      qnxMartPictureS3Key: json['qnx_mart_picture_s3_key']?.toString(),
      marketingPartnerPictureUrl:
      json['marketing_partner_picture_url']?.toString(),
      marketingPartnerPictureS3Key:
      json['marketing_partner_picture_s3_key']?.toString(),
      uploadedAgreementPdfUrl:
      json['uploaded_agreement_pdf_url']?.toString(),
      uploadedAgreementPdfS3Key:
      json['uploaded_agreement_pdf_s3_key']?.toString(),
      status: json['status'] ?? 'pending',
      agreementStage: json['agreement_stage'] ?? 'draft',
      createdBy: json['created_by'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at']?.toString(),
      partnerSignedAt: json['partner_signed_at']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // ============================================================
  // ✅ STATE GETTERS
  // ============================================================
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' && agreementStage == 'finalized';
  bool get isRejected => status == 'rejected';
  bool get isTerminated => agreementStage == 'terminated';
  bool get isSignedByPartner => agreementStage == 'signed_by_partner';
  bool get isDraft => agreementStage == 'draft';

  /// Partner ने sign करू शकतो का?
  bool get canPartnerSign =>
      !isTerminated &&
          !isApproved &&
          !isRejected &&
          (isDraft || agreementStage == 'signed_by_partner');

  /// Partner ने reject करू शकतो का?
  bool get canPartnerReject =>
      !isTerminated && !isApproved && !isRejected && !isSignedByPartner;

  /// PDF download available का? (फक्त approved/finalized)
  bool get canDownloadPdf => isApproved && !isTerminated;

  // ============================================================
  // ✅ RESOLVE URLs
  // ============================================================
  String? get pdfUrl {
    if (uploadedAgreementPdfUrl != null &&
        uploadedAgreementPdfUrl!.isNotEmpty) {
      return uploadedAgreementPdfUrl;
    }
    final k = uploadedAgreementPdfS3Key;
    if (k != null && k.isNotEmpty) {
      return k.startsWith('http')
          ? k
          : 'https://qnxmart.s3.amazonaws.com/$k';
    }
    return null;
  }

  bool get hasPdf => pdfUrl != null;

  String? get qnxSignDisplayUrl {
    if (qnxMartSignUrl != null && qnxMartSignUrl!.isNotEmpty) {
      return qnxMartSignUrl;
    }
    final k = qnxMartSignS3Key;
    if (k != null && k.isNotEmpty) {
      return k.startsWith('http')
          ? k
          : 'https://qnxmart.s3.amazonaws.com/$k';
    }
    return null;
  }

  String? get mpSignDisplayUrl {
    if (marketingPartnerSignUrl != null &&
        marketingPartnerSignUrl!.isNotEmpty) {
      return marketingPartnerSignUrl;
    }
    final k = marketingPartnerSignS3Key;
    if (k != null && k.isNotEmpty) {
      return k.startsWith('http')
          ? k
          : 'https://qnxmart.s3.amazonaws.com/$k';
    }
    return null;
  }

  String? get qnxPictureDisplayUrl {
    if (qnxMartPictureUrl != null && qnxMartPictureUrl!.isNotEmpty) {
      return qnxMartPictureUrl;
    }
    final k = qnxMartPictureS3Key;
    if (k != null && k.isNotEmpty) {
      return k.startsWith('http')
          ? k
          : 'https://qnxmart.s3.amazonaws.com/$k';
    }
    return null;
  }

  String? get mpPictureDisplayUrl {
    if (marketingPartnerPictureUrl != null &&
        marketingPartnerPictureUrl!.isNotEmpty) {
      return marketingPartnerPictureUrl;
    }
    final k = marketingPartnerPictureS3Key;
    if (k != null && k.isNotEmpty) {
      return k.startsWith('http')
          ? k
          : 'https://qnxmart.s3.amazonaws.com/$k';
    }
    return null;
  }

  bool get hasImages =>
      qnxSignDisplayUrl != null ||
          mpSignDisplayUrl != null ||
          qnxPictureDisplayUrl != null ||
          mpPictureDisplayUrl != null;
}

// ============================================================
// ✅ LIST RESPONSE (my-list)
// ============================================================
class MarketingPartnerAgreementListResponse {
  final bool success;
  final String message;
  final int count;
  final List<MarketingPartnerAgreementData> data;

  MarketingPartnerAgreementListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MarketingPartnerAgreementListResponse.fromJson(
      Map<String, dynamic> json) {
    return MarketingPartnerAgreementListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => MarketingPartnerAgreementData.fromJson(e))
          .toList(),
    );
  }
}

// ============================================================
// ✅ CREATE RESPONSE
// ============================================================
class MarketingPartnerAgreementCreateResponse {
  final bool success;
  final String message;
  final MarketingPartnerAgreementData? data;

  MarketingPartnerAgreementCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MarketingPartnerAgreementCreateResponse.fromJson(
      Map<String, dynamic> json) {
    return MarketingPartnerAgreementCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MarketingPartnerAgreementData.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================
// ✅ PARTNER SIGN RESPONSE
// ============================================================
class MarketingPartnerSignResponse {
  final bool success;
  final String message;
  final PartnerSignData? data;

  MarketingPartnerSignResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MarketingPartnerSignResponse.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerSignResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PartnerSignData.fromJson(json['data'])
          : null,
    );
  }
}

class PartnerSignData {
  final int agreementId;
  final String agreementNumber;
  final String status;
  final String agreementStage;
  final String? partnerSignedAt;
  final String? adharNumber;
  final String? panNumber;
  final String? marketingPartnerSignUrl;
  final String? rejectionReason;

  PartnerSignData({
    required this.agreementId,
    required this.agreementNumber,
    required this.status,
    required this.agreementStage,
    this.partnerSignedAt,
    this.adharNumber,
    this.panNumber,
    this.marketingPartnerSignUrl,
    this.rejectionReason,
  });

  factory PartnerSignData.fromJson(Map<String, dynamic> json) {
    return PartnerSignData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      status: json['status'] ?? '',
      agreementStage: json['agreement_stage'] ?? '',
      partnerSignedAt: json['partner_signed_at']?.toString(),
      adharNumber: json['adhar_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      marketingPartnerSignUrl:
      json['marketing_partner_sign_url']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

// ============================================================
// ✅ CREATE REQUEST MODEL (QNX Admin साठी)
// ============================================================
class MarketingPartnerAgreementModel {
  final String agreementNumber;
  final int marketingPartnerId;
  final String agreementRole;
  final String agreementStartDate;
  final String agreementEndDate;
  final String marketingPartnerName;
  final String marketingPartnerAddress;
  final String companyCommissionPercentage;
  final String profitSharePercentage;
  final String sellingCommissionPercentage;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String? remarks;
  final String? adharNumber;
  final String? panNumber;
  final Uint8List? qnxMartSign;
  final Uint8List? marketingPartnerSign;
  final Uint8List? qnxMartPicture;
  final Uint8List? marketingPartnerPicture;
  final Uint8List? uploadedAgreementPdf;

  MarketingPartnerAgreementModel({
    required this.agreementNumber,
    required this.marketingPartnerId,
    this.agreementRole = 'marketing_partner',
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.marketingPartnerName,
    required this.marketingPartnerAddress,
    required this.companyCommissionPercentage,
    required this.profitSharePercentage,
    required this.sellingCommissionPercentage,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    this.remarks,
    this.adharNumber,
    this.panNumber,
    this.qnxMartSign,
    this.marketingPartnerSign,
    this.qnxMartPicture,
    this.marketingPartnerPicture,
    this.uploadedAgreementPdf,
  });
}