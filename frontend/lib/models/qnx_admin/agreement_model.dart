// lib/models/agreement_model.dart

// Agreement Model (for creating agreement)
import 'dart:typed_data';

class AgreementModel {
  final String? agreementNumber; // ✅ ADD THIS
  final String agreementRole;
  final bool applyOnAllProducts;
  final String agreementStartDate;
  final String agreementEndDate;
  final String sellingCommissionPercentage;
  final String companyOwnerName;
  final String companyAddress;
  final double globalProfit;
  final String? sellerAdharNumber;
  final String? ownerAdharNumber;
  final String? sellerPanNumber;
  final String? ownerPanNumber;
  final String profitSharePercentage;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String? remarks;
  final int? companyId;
  final int? marketingPartnerId;
  final List<Map<String, dynamic>> agreementProducts;
  final Uint8List? qnxMartSign;
  final Uint8List? companySign;
  final Uint8List? qnxMartPicture;
  final Uint8List? companyPicture;
  final Uint8List? uploadedAgreementPdf;


  AgreementModel({
    this.agreementNumber,
    required this.agreementRole,
    required this.applyOnAllProducts,
    required this.agreementStartDate,
    required this.agreementEndDate,
    required this.companyOwnerName,
    required this.companyAddress,
    required this.globalProfit,
    this.sellerAdharNumber,
    this.ownerAdharNumber,
    this.sellerPanNumber,
    this.ownerPanNumber,
    required this.profitSharePercentage,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    this.remarks,
    this.companyId,
    this.marketingPartnerId,
    this.agreementProducts = const [],
    this.qnxMartSign,
    this.companySign,
    this.qnxMartPicture,
    this.companyPicture,
    this.uploadedAgreementPdf,
    required this.sellingCommissionPercentage,
  });
}

// Agreement Company Model
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

// Agreement Product Model
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

// Agreement Data (for displaying agreement from API response)
class AgreementData {
  final int id;
  final String agreementNumber;
  final String startDate;
  final String endDate;
  final String companyOwnerName;
  final String companyAddress;
  final dynamic globalProfit;
  final dynamic sellerAdharNumber;
  final dynamic ownerAdharNumber;
  final dynamic sellerPanNumber;
  final dynamic ownerPanNumber;
  final String profitSharePercentage;
  final String additionalPoints;
  final String qnxMartRepresentative;
  final String qnxMartSignUrl;
  final String companySignUrl;
  final String qnxMartPictureUrl;
  final String companyPictureUrl;
  final String qnxMartSignS3Key;
  final String companySignS3Key;
  final String qnxMartPictureS3Key;
  final String companyPictureS3Key;
  final String createdAt;
  final int company;
  final String agreementRole;
  final String? remarks;
  final String status;
  final String? companyName;
  final String? marketingPartnerName;
  final String sellingCommissionPercentage;
  final String? rejectionReason;
  final String? uploadedAgreementPdfUrl;  // ✅ PDF URL साठी
  final String? uploadedAgreementPdfS3Key;
  final List<AgreementProductData>? agreementProducts;


  String get pdfUrl {
    if (uploadedAgreementPdfUrl != null && uploadedAgreementPdfUrl!.isNotEmpty) {
      return uploadedAgreementPdfUrl!;
    }
    if (uploadedAgreementPdfS3Key != null && uploadedAgreementPdfS3Key!.isNotEmpty) {
      return 'https://qnxmart.s3.amazonaws.com/${uploadedAgreementPdfS3Key!}';
    }
    return '';
  }

  // ✅ ADD THIS GETTER - Check if PDF exists
  bool get hasPdf =>
      (uploadedAgreementPdfUrl != null && uploadedAgreementPdfUrl!.isNotEmpty) ||
          (uploadedAgreementPdfS3Key != null && uploadedAgreementPdfS3Key!.isNotEmpty);

  // ✅ ADD THIS GETTER - Get filename from S3 key
  String get pdfFileName {
    if (uploadedAgreementPdfS3Key != null && uploadedAgreementPdfS3Key!.isNotEmpty) {
      return uploadedAgreementPdfS3Key!.split('/').last;
    }
    return 'agreement.pdf';
  }

  AgreementData({
    required this.id,
    required this.agreementNumber,
    required this.startDate,
    required this.endDate,
    required this.sellingCommissionPercentage,
    required this.companyOwnerName,
    required this.companyAddress,
    this.globalProfit,
    this.sellerAdharNumber,
    this.ownerAdharNumber,
    this.sellerPanNumber,
    this.ownerPanNumber,
    required this.profitSharePercentage,
    required this.additionalPoints,
    required this.qnxMartRepresentative,
    required this.qnxMartSignUrl,
    required this.companySignUrl,
    required this.qnxMartPictureUrl,
    required this.companyPictureUrl,
    required this.qnxMartSignS3Key,
    required this.companySignS3Key,
    required this.qnxMartPictureS3Key,
    required this.companyPictureS3Key,
    required this.createdAt,
    required this.company,
    required this.agreementRole,

    this.remarks,
    required this.status,
    this.companyName,
    this.marketingPartnerName,
    this.rejectionReason,
    this.uploadedAgreementPdfUrl,
    this.uploadedAgreementPdfS3Key,
    this.agreementProducts,
  });

  factory AgreementData.fromJson(Map<String, dynamic> json) {
    // ✅ PDF URL parse
    final s3Key = json['uploaded_agreement_pdf_s3_key']?.toString();
    final url = json['uploaded_agreement_pdf_url']?.toString();

    String? pdfUrl = url;
    if ((pdfUrl == null || pdfUrl.isEmpty) && s3Key != null && s3Key.isNotEmpty) {
      pdfUrl = 'https://qnxmart.s3.amazonaws.com/$s3Key';
    }

    // ✅ Products parse — new API uses "products" (not "agreement_products")
    List<AgreementProductData>? products;
    if (json['products'] != null && json['products'] is List) {
      products = (json['products'] as List).map((e) {
        return AgreementProductData(
          product: e['product_id'] ?? 0,
          profitPercentage: e['profit_percentage']?.toString() ?? '0',
          productName: e['product_name']?.toString(),
        );
      }).toList();
    } else if (json['agreement_products'] != null && json['agreement_products'] is List) {
      products = (json['agreement_products'] as List)
          .map((e) => AgreementProductData.fromJson(e))
          .toList();
    }

    return AgreementData(
      // ✅ "agreement_id" not "id"
      id: json['agreement_id'] ?? json['id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      startDate: json['agreement_start_date'] ?? '',
      endDate: json['agreement_end_date'] ?? '',
      companyOwnerName: json['company_owner_name'] ?? '',
      companyAddress: json['company_address'] ?? '',
      globalProfit: json['global_profit'],
      sellerAdharNumber: json['seller_adhar_number'] ?? json['selle_radhar_number'],
      ownerAdharNumber: json['owner_adhar_number'],
      sellerPanNumber: json['seller_pan_number'],
      ownerPanNumber: json['owner_pan_number'],
      profitSharePercentage: json['profit_share_percentage']?.toString() ?? '',
      sellingCommissionPercentage: json['selling_commission_percentage']?.toString() ?? '',
      additionalPoints: json['additional_points'] ?? '',
      qnxMartRepresentative: json['qnx_mart_representative'] ?? '',
      qnxMartSignUrl: json['qnx_mart_sign_url'] ?? '',
      companySignUrl: json['company_sign_url'] ?? '',
      qnxMartPictureUrl: json['qnx_mart_picture_url'] ?? '',
      companyPictureUrl: json['company_picture_url'] ?? '',
      qnxMartSignS3Key: json['qnx_mart_sign_s3_key'] ?? '',
      companySignS3Key: json['company_sign_s3_key'] ?? '',
      qnxMartPictureS3Key: json['qnx_mart_picture_s3_key'] ?? '',
      companyPictureS3Key: json['company_picture_s3_key'] ?? '',
      createdAt: json['created_at'] ?? '',
      // ✅ "company_id" not "company"
      company: json['company_id'] ?? json['company'] ?? 0,
      agreementRole: json['agreement_role'] ?? '',
      remarks: json['remarks']?.toString(),
      status: json['status'] ?? 'pending',
      companyName: json['company_name']?.toString(),
      marketingPartnerName: json['marketing_partner_name']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      uploadedAgreementPdfUrl: pdfUrl,
      uploadedAgreementPdfS3Key: s3Key,
      agreementProducts: products,
    );
  }
}

// Agreement List Response
// Agreement List Response
class AgreementListResponse {
  final String status;
  final String message;
  final int total;
  final List<AgreementData> data;

  AgreementListResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory AgreementListResponse.fromJson(Map<String, dynamic> json) {
    // ✅ New API returns "success": true
    final bool success = json['success'] ?? (json['status'] == 'success');
    return AgreementListResponse(
      status: success ? 'success' : 'error',
      message: json['message'] ?? '',
      // ✅ New API uses "count"
      total: json['count'] ?? json['total'] ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => AgreementData.fromJson(e))
          .toList(),
    );
  }
}

// Agreement Response (for create)
class AgreementResponse {
  final String status;
  final String message;
  final AgreementData? data;

  AgreementResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AgreementResponse.fromJson(Map<String, dynamic> json) {
    // ✅ New API returns "success": true
    final bool success = json['success'] ?? (json['status'] == 'success');
    return AgreementResponse(
      status: success ? 'success' : 'error',
      message: json['message'] ?? '',
      data: json['data'] != null ? AgreementData.fromJson(json['data']) : null,
    );
  }
}

// Approve/Reject Response
class AgreementActionResponse {
  final String message;

  AgreementActionResponse({required this.message});

  factory AgreementActionResponse.fromJson(Map<String, dynamic> json) {
    return AgreementActionResponse(
      message: json['message'] ?? '',
    );
  }
}

// Agreement Company Response
class AgreementCompanyResponse {
  final bool status;
  final String message;
  final List<AgreementCompanyModel> data;

  AgreementCompanyResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AgreementCompanyResponse.fromJson(Map<String, dynamic> json) {
    final List list = json['data'] ?? [];
    return AgreementCompanyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: list.map((e) => AgreementCompanyModel.fromJson(e)).toList(),
    );
  }
}

// Agreement Product Response
class AgreementProductResponse {
  final String status;
  final List<AgreementProductModel> data;

  AgreementProductResponse({
    required this.status,
    required this.data,
  });

  factory AgreementProductResponse.fromJson(Map<String, dynamic> json) {
    final List list = json['data'] ?? [];
    return AgreementProductResponse(
      status: json['status'] ?? '',
      data: list.map((e) => AgreementProductModel.fromJson(e)).toList(),
    );
  }
}

class AgreementProductData {
  final int product;
  final String profitPercentage;
  final String? productName;

  AgreementProductData({
    required this.product,
    required this.profitPercentage,
    this.productName,
  });

  factory AgreementProductData.fromJson(Map<String, dynamic> json) {
    return AgreementProductData(
      // ✅ "product_id" or "product"
      product: json['product_id'] ?? json['product'] ?? 0,
      profitPercentage: json['profit_percentage']?.toString() ?? '0',
      productName: json['product_name']?.toString(),
    );
  }
}




// ============================================================
// ✅ APPROVE AGREEMENT RESPONSE (New API)
// ============================================================
class CompanyAgreementApproveResponse {
  final bool success;
  final String message;
  final CompanyAgreementApproveData? data;

  CompanyAgreementApproveResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CompanyAgreementApproveResponse.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementApproveResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CompanyAgreementApproveData.fromJson(json['data'])
          : null,
    );
  }
}

class CompanyAgreementApproveData {
  final int agreementId;
  final String agreementNumber;
  final int companyId;
  final String status;
  final int? approvedBy;
  final String? approvedAt;

  CompanyAgreementApproveData({
    required this.agreementId,
    required this.agreementNumber,
    required this.companyId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
  });

  factory CompanyAgreementApproveData.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementApproveData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      companyId: json['company_id'] ?? 0,
      status: json['status'] ?? '',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at']?.toString(),
    );
  }
}

// ============================================================
// ✅ REJECT AGREEMENT RESPONSE (New API)
// ============================================================
class CompanyAgreementRejectResponse {
  final bool success;
  final String message;
  final CompanyAgreementRejectData? data;

  CompanyAgreementRejectResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CompanyAgreementRejectResponse.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementRejectResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CompanyAgreementRejectData.fromJson(json['data'])
          : null,
    );
  }
}

class CompanyAgreementRejectData {
  final int agreementId;
  final String agreementNumber;
  final int companyId;
  final String status;
  final String? rejectionReason;

  CompanyAgreementRejectData({
    required this.agreementId,
    required this.agreementNumber,
    required this.companyId,
    required this.status,
    this.rejectionReason,
  });

  factory CompanyAgreementRejectData.fromJson(Map<String, dynamic> json) {
    return CompanyAgreementRejectData(
      agreementId: json['agreement_id'] ?? 0,
      agreementNumber: json['agreement_number'] ?? '',
      companyId: json['company_id'] ?? 0,
      status: json['status'] ?? '',
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

