// lib/models/qnx_admin/agreement_model.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
// ============================================================
// ENUMS
// ============================================================
enum AgreementType {
  company,
  marketingPartner,
}

extension AgreementTypeExt on AgreementType {
  String get label => this == AgreementType.company
      ? 'QNX Admin to Company'
      : 'QNX Admin to Marketing Partner';

  IconData get icon => this == AgreementType.company
      ? Icons.business_rounded
      : Icons.handshake_rounded;

  Color get color => this == AgreementType.company
      ? const Color(0xFF6C63FF)
      : const Color(0xFFFF6584);

  String get apiType => this == AgreementType.company ? 'company' : 'marketing_partner';
}

// ============================================================
// COMPANY AGREEMENT MODEL (for Create request)
// ============================================================
class CompanyAgreementCreateRequest {
  final int companyId;
  final String agreementStartDate;
  final String agreementEndDate;
  final String companyOwnerName;
  final String companyAddress;
  final String? sellerAdharNumber;
  final String? sellerPanNumber;
  final String? ownerAdharNumber;
  final String? ownerPanNumber;
  final String qnxMartRepresentative;
  final String additionalPoints;
  final String? remarks;
  final List<AgreementProductItem> agreementProducts;
  final Uint8List? qnxMartSign;
  final Uint8List? qnxMartPicture;
  final Uint8List? companyPicture;
  final Uint8List? uploadedAgreementPdf;

  CompanyAgreementCreateRequest({
    required this.companyId,
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.companyOwnerName,
    required this.companyAddress,
    this.sellerAdharNumber,
    this.sellerPanNumber,
    this.ownerAdharNumber,
    this.ownerPanNumber,
    required this.qnxMartRepresentative,
    required this.additionalPoints,
    this.remarks,
    this.agreementProducts = const [],
    this.qnxMartSign,
    this.qnxMartPicture,
    this.companyPicture,
    this.uploadedAgreementPdf,
  });
}

class AgreementProductItem {
  final int product;
  final String profitPercentage;

  AgreementProductItem({required this.product, required this.profitPercentage});

  Map<String, dynamic> toJson() => {
    'product': product,
    'profit_percentage': profitPercentage,
  };
}

// ============================================================
// MARKETING PARTNER AGREEMENT MODEL (for Create request)
// ============================================================
class MarketingPartnerAgreementCreateRequest {
  final int marketingPartnerId;
  final String agreementStartDate;
  final String agreementEndDate;
  final String marketingPartnerName;
  final String marketingPartnerAddress;
  final String? adharNumber;
  final String? panNumber;
  final String companyCommissionPercentage;
  final String profitSharePercentage;
  final String sellingCommissionPercentage;
  final String qnxMartRepresentative;
  final String additionalPoints;
  final String? remarks;
  final Uint8List? qnxMartSign;
  final Uint8List? qnxMartPicture;
  final Uint8List? marketingPartnerPicture;
  final Uint8List? uploadedAgreementPdf;

  MarketingPartnerAgreementCreateRequest({
    required this.marketingPartnerId,
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.marketingPartnerName,
    required this.marketingPartnerAddress,
    this.adharNumber,
    this.panNumber,
    required this.companyCommissionPercentage,
    required this.profitSharePercentage,
    required this.sellingCommissionPercentage,
    required this.qnxMartRepresentative,
    required this.additionalPoints,
    this.remarks,
    this.qnxMartSign,
    this.qnxMartPicture,
    this.marketingPartnerPicture,
    this.uploadedAgreementPdf,
  });
}

// ============================================================
// AGREEMENT PRODUCT DATA (from list response)
// ============================================================
class AgreementProductData {
  final int productId;
  final String productName;
  final double profitPercentage;
  final bool isActive;

  AgreementProductData({
    required this.productId,
    required this.productName,
    required this.profitPercentage,
    required this.isActive,
  });

  factory AgreementProductData.fromJson(Map<String, dynamic> json) {
    return AgreementProductData(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      profitPercentage: (json['profit_percentage'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}

// ============================================================
// COMPANY AGREEMENT DATA (from list response)
// ============================================================
class CompanyAgreementData {
  final int agreementId;
  final String agreementNumber;
  final int companyId;
  final String companyName;
  final String agreementRole;
  final String agreementStartDate;
  final String agreementEndDate;
  final String companyOwnerName;
  final String companyAddress;
  final String? sellerAdharNumber;
  final String? ownerAdharNumber;
  final String? sellerPanNumber;
  final String? ownerPanNumber;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String? qnxMartSignUrl;
  final String? companySignUrl;
  final String? qnxMartPictureUrl;
  final String? companyPictureUrl;
  final String? uploadedAgreementPdfUrl;
  final String? remarks;
  final String status;
  final String agreementStage;
  final int createdBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? companySignedAt;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;
  final List<AgreementProductData> products;

  CompanyAgreementData({
    required this.agreementId,
    required this.agreementNumber,
    required this.companyId,
    required this.companyName,
    required this.agreementRole,
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.companyOwnerName,
    required this.companyAddress,
    this.sellerAdharNumber,
    this.ownerAdharNumber,
    this.sellerPanNumber,
    this.ownerPanNumber,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    this.qnxMartSignUrl,
    this.companySignUrl,
    this.qnxMartPictureUrl,
    this.companyPictureUrl,
    this.uploadedAgreementPdfUrl,
    this.remarks,
    required this.status,
    required this.agreementStage,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.companySignedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    required this.products,
  });

  factory CompanyAgreementData.fromJson(Map<String, dynamic> json) {
    List<AgreementProductData> productList = [];
    if (json['products'] is List) {
      productList = (json['products'] as List)
          .map((e) => AgreementProductData.fromJson(e))
          .toList();
    }

    return CompanyAgreementData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      companyId: json['company_id'] ?? 0,
      companyName: json['company_name'] ?? '',
      agreementRole: json['agreement_role'] ?? '',
      agreementStartDate: json['agreement_start_date'] ?? '',
      agreementEndDate: json['agreement_end_date'] ?? '',
      companyOwnerName: json['company_owner_name'] ?? '',
      companyAddress: json['company_address'] ?? '',
      sellerAdharNumber: json['seller_adhar_number'],
      ownerAdharNumber: json['owner_adhar_number'],
      sellerPanNumber: json['seller_pan_number'],
      ownerPanNumber: json['owner_pan_number'],
      additionalPoints: json['additional_points'] ?? '',
      qnxMartRepresentative: json['qnx_mart_representative'] ?? '',
      qnxMartSignUrl: json['qnx_mart_sign_url'],
      companySignUrl: json['company_sign_url'],
      qnxMartPictureUrl: json['qnx_mart_picture_url'],
      companyPictureUrl: json['company_picture_url'],
      uploadedAgreementPdfUrl: json['uploaded_agreement_pdf_url'],
      remarks: json['remarks'],
      status: json['status'] ?? 'pending',
      agreementStage: json['agreement_stage'] ?? 'draft',
      createdBy: json['created_by'] ?? 0,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
      companySignedAt: json['company_signed_at'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      products: productList,
    );
  }

  bool get isApproved => status == 'approved' && agreementStage == 'finalized';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isTerminated => agreementStage == 'terminated';
}

// ============================================================
// MARKETING PARTNER AGREEMENT DATA (from list response)
// ============================================================
class MarketingPartnerAgreementData {
  final int agreementId;
  final String agreementNumber;
  final int marketingPartnerId;
  final String marketingPartnerName;
  final String agreementRole;
  final String agreementStartDate;
  final String agreementEndDate;
  final String marketingPartnerAddress;
  final String? adharNumber;
  final String? panNumber;
  final String companyCommissionPercentage;
  final String profitSharePercentage;
  final String sellingCommissionPercentage;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String? remarks;
  final String? qnxMartSignUrl;
  final String? marketingPartnerSignUrl;
  final String? qnxMartPictureUrl;
  final String? marketingPartnerPictureUrl;
  final String? uploadedAgreementPdfUrl;
  final String status;
  final String agreementStage;
  final int createdBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? partnerSignedAt;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;

  MarketingPartnerAgreementData({
    required this.agreementId,
    required this.agreementNumber,
    required this.marketingPartnerId,
    required this.marketingPartnerName,
    required this.agreementRole,
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.marketingPartnerAddress,
    this.adharNumber,
    this.panNumber,
    required this.companyCommissionPercentage,
    required this.profitSharePercentage,
    required this.sellingCommissionPercentage,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    this.remarks,
    this.qnxMartSignUrl,
    this.marketingPartnerSignUrl,
    this.qnxMartPictureUrl,
    this.marketingPartnerPictureUrl,
    this.uploadedAgreementPdfUrl,
    required this.status,
    required this.agreementStage,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.partnerSignedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketingPartnerAgreementData.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerAgreementData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartnerName: json['marketing_partner_name'] ?? '',
      agreementRole: json['agreement_role'] ?? '',
      agreementStartDate: json['agreement_start_date'] ?? '',
      agreementEndDate: json['agreement_end_date'] ?? '',
      marketingPartnerAddress: json['marketing_partner_address'] ?? '',
      adharNumber: json['adhar_number'],
      panNumber: json['pan_number'],
      companyCommissionPercentage: json['company_commission_percentage']?.toString() ?? '0',
      profitSharePercentage: json['profit_share_percentage']?.toString() ?? '0',
      sellingCommissionPercentage: json['selling_commission_percentage']?.toString() ?? '0',
      additionalPoints: json['additional_points'] ?? '',
      qnxMartRepresentative: json['qnx_mart_representative'] ?? '',
      remarks: json['remarks'],
      qnxMartSignUrl: json['qnx_mart_sign_url'],
      marketingPartnerSignUrl: json['marketing_partner_sign_url'],
      qnxMartPictureUrl: json['qnx_mart_picture_url'],
      marketingPartnerPictureUrl: json['marketing_partner_picture_url'],
      uploadedAgreementPdfUrl: json['uploaded_agreement_pdf_url'],
      status: json['status'] ?? 'pending',
      agreementStage: json['agreement_stage'] ?? 'draft',
      createdBy: json['created_by'] ?? 0,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
      partnerSignedAt: json['partner_signed_at'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isApproved => status == 'approved' && agreementStage == 'finalized';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isTerminated => agreementStage == 'terminated';
}

// ============================================================
// RESPONSE MODELS
// ============================================================

class CompanyAgreementCreateResponse {
  final bool success;
  final String message;
  final CompanyAgreementData? data;

  CompanyAgreementCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CompanyAgreementCreateResponse.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CompanyAgreementData.fromJson(json['data'])
          : null,
    );
  }
}

class CompanyAgreementListResponse {
  final bool success;
  final String message;
  final int count;
  final List<CompanyAgreementData> data;

  CompanyAgreementListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory CompanyAgreementListResponse.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => CompanyAgreementData.fromJson(e))
          .toList(),
    );
  }
}

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

// Approve/Reject Response (common for both)
class AgreementActionResponse {
  final bool success;
  final String message;
  final AgreementActionData? data;

  AgreementActionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AgreementActionResponse.fromJson(Map<String, dynamic> json) {
    return AgreementActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AgreementActionData.fromJson(json['data'])
          : null,
    );
  }
}

class AgreementActionData {
  final int agreementId;
  final String agreementNumber;
  final String? status;
  final String? agreementStage;
  final String? rejectionReason;

  AgreementActionData({
    required this.agreementId,
    required this.agreementNumber,
    this.status,
    this.agreementStage,
    this.rejectionReason,
  });

  factory AgreementActionData.fromJson(Map<String, dynamic> json) {
    return AgreementActionData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      status: json['status'],
      agreementStage: json['agreement_stage'],
      rejectionReason: json['rejection_reason'],
    );
  }
}

// Terminate Response
class AgreementTerminateResponse {
  final bool success;
  final String message;
  final AgreementActionData? data;

  AgreementTerminateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AgreementTerminateResponse.fromJson(Map<String, dynamic> json) {
    return AgreementTerminateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AgreementActionData.fromJson(json['data'])
          : null,
    );
  }
}

// ============================================================
// ✅ RE-ADD: AgreementCompanyModel (जुना वापर होत आहे)
// ============================================================
class AgreementCompanyModel {
  final int id;
  final String name;
  final String ownerName;

  AgreementCompanyModel({
    required this.id,
    required this.name,
    required this.ownerName,
  });

  factory AgreementCompanyModel.fromJson(Map<String, dynamic> json) {
    return AgreementCompanyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
    );
  }
}

// ============================================================
// ✅ RE-ADD: AgreementProductModel (जुना वापर होत आहे)
// ============================================================
class AgreementProductModel {
  final int id;
  final String thumbnailS3Key;
  final String name;
  final double price;
  final double finalPrice;
  final int stockQuantity;
  final String status;

  AgreementProductModel({
    required this.id,
    required this.thumbnailS3Key,
    required this.name,
    required this.price,
    required this.finalPrice,
    required this.stockQuantity,
    required this.status,
  });

  factory AgreementProductModel.fromJson(Map<String, dynamic> json) {
    return AgreementProductModel(
      id: json['id'] ?? 0,
      thumbnailS3Key: json['thumbnail_s3_key'] ?? json['thumbnail'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      finalPrice: (json['final_price'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}