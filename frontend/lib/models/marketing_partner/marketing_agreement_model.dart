// ============================================================
// ✅ MARKETING PARTNER AGREEMENT MODEL
// ============================================================

import 'dart:typed_data';
// ============================================================
// ✅ MARKETING PARTNER AGREEMENT MODEL
// ============================================================

import 'dart:typed_data';

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

  // ✅ PDF — both url + s3 key
  final String? uploadedAgreementPdfUrl;
  final String? uploadedAgreementPdfS3Key;

  final String status;
  final int? createdBy;
  final int? approvedBy;
  final String? approvedAt;
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
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketingPartnerAgreementData.fromJson(Map<String, dynamic> json) {
    // ✅ Check uploaded_files object (returned by create endpoint)
    Map<String, dynamic>? uploadedFiles =
    json['uploaded_files'] as Map<String, dynamic>?;

    // ✅ Helper to extract key/url from either top-level or uploaded_files
    String? pickKey(String topKey, String filesKey) {
      final top = json[topKey]?.toString();
      if (top != null && top.isNotEmpty) return top;
      final f = uploadedFiles?[filesKey];
      if (f is Map) {
        final k = f['key']?.toString();
        if (k != null && k.isNotEmpty) return k;
      }
      return top;
    }

    String? pickUrl(String topKey, String filesKey) {
      final top = json[topKey]?.toString();
      if (top != null && top.isNotEmpty) return top;
      final f = uploadedFiles?[filesKey];
      if (f is Map) {
        final u = f['url']?.toString();
        if (u != null && u.isNotEmpty) return u;
      }
      return top;
    }

    // PDF
    String? pdfKey = pickKey(
      'uploaded_agreement_pdf_s3_key',
      'uploaded_agreement_pdf',
    );
    String? pdfUrl = pickUrl(
      'uploaded_agreement_pdf_url',
      'uploaded_agreement_pdf',
    );

    // Sign / picture keys (also exposed so the detail view can render them)
    String? qnxSignKey =
    pickKey('qnx_mart_sign_s3_key', 'qnx_mart_sign');
    String? qnxSignUrl =
    pickUrl('qnx_mart_sign_url', 'qnx_mart_sign');
    String? mpSignKey = pickKey(
      'marketing_partner_sign_s3_key',
      'marketing_partner_sign',
    );
    String? mpSignUrl = pickUrl(
      'marketing_partner_sign_url',
      'marketing_partner_sign',
    );
    String? qnxPicKey =
    pickKey('qnx_mart_picture_s3_key', 'qnx_mart_picture');
    String? qnxPicUrl =
    pickUrl('qnx_mart_picture_url', 'qnx_mart_picture');
    String? mpPicKey = pickKey(
      'marketing_partner_picture_s3_key',
      'marketing_partner_picture',
    );
    String? mpPicUrl = pickUrl(
      'marketing_partner_picture_url',
      'marketing_partner_picture',
    );

    return MarketingPartnerAgreementData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartnerName: json['marketing_partner_name']?.toString(),
      agreementRole: json['agreement_role'] ?? 'marketing_partner',
      agreementStartDate: json['agreement_start_date'] ?? '',
      agreementEndDate: json['agreement_end_date'] ?? '',
      marketingPartnerAddress:
      json['marketing_partner_address']?.toString(),
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
      qnxMartSignUrl: qnxSignUrl,
      qnxMartSignS3Key: qnxSignKey,
      marketingPartnerSignUrl: mpSignUrl,
      marketingPartnerSignS3Key: mpSignKey,
      qnxMartPictureUrl: qnxPicUrl,
      qnxMartPictureS3Key: qnxPicKey,
      marketingPartnerPictureUrl: mpPicUrl,
      marketingPartnerPictureS3Key: mpPicKey,
      uploadedAgreementPdfUrl: pdfUrl,
      uploadedAgreementPdfS3Key: pdfKey,
      status: json['status'] ?? 'pending',
      createdBy: json['created_by'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // ✅ Resolve full PDF URL (url → s3 key → https://qnxmart.s3.amazonaws.com/key)
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

  // ✅ Resolvers for sign / picture
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
// ✅ MARKETING PARTNER AGREEMENT LIST RESPONSE
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

  factory MarketingPartnerAgreementListResponse.fromJson(Map<String, dynamic> json) {
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
// ✅ MARKETING PARTNER AGREEMENT CREATE RESPONSE
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

  factory MarketingPartnerAgreementCreateResponse.fromJson(Map<String, dynamic> json) {
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
// ✅ MARKETING PARTNER AGREEMENT APPROVE RESPONSE
// ============================================================
class MarketingPartnerAgreementApproveResponse {
  final bool success;
  final String message;
  final MarketingPartnerAgreementData? data;

  MarketingPartnerAgreementApproveResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MarketingPartnerAgreementApproveResponse.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerAgreementApproveResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MarketingPartnerAgreementData.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================
// ✅ MARKETING PARTNER AGREEMENT REJECT RESPONSE
// ============================================================
class MarketingPartnerAgreementRejectResponse {
  final bool success;
  final String message;
  final MarketingPartnerAgreementData? data;

  MarketingPartnerAgreementRejectResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MarketingPartnerAgreementRejectResponse.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerAgreementRejectResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MarketingPartnerAgreementData.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================
// ✅ MARKETING PARTNER AGREEMENT CREATE MODEL (Request)
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
    this.adharNumber,     // ✅ ADD
    this.panNumber,
    this.qnxMartSign,
    this.marketingPartnerSign,
    this.qnxMartPicture,
    this.marketingPartnerPicture,
    this.uploadedAgreementPdf,
  });
}