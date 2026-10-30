// lib/models/marketing_partner/product_refral_model.dart

class ApprovedProductModel {
  final int id;
  final String name;
  final String price;
  final String? categoryName;
  final String? brandName;
  final String? thumbnail;
  final String? description;
  final String? companyName;
  final String? unitName;
  final String? status;
  final double? finalPrice;
  final String? slug;

  ApprovedProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.categoryName,
    this.brandName,
    this.thumbnail,
    this.description,
    this.companyName,
    this.unitName,
    this.status,
    this.finalPrice,
    this.slug,
  });

  factory ApprovedProductModel.fromJson(Map<String, dynamic> json) {
    return ApprovedProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      price: json['price']?.toString() ?? '0',
      categoryName: json['category_name'],
      brandName: json['brand_name'],
      thumbnail: json['thumbnail_s3_key'] ?? json['thumbnail'],
      description: json['description'],
      companyName: json['company_name'],
      unitName: json['unit_name'],
      status: json['status'],
      finalPrice: json['final_price']?.toDouble(),
      slug: json['slug'],
    );
  }
}

class ApprovedProductListResponse {
  final bool status;
  final String message;
  final int count;
  final List<ApprovedProductModel> data;

  ApprovedProductListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ApprovedProductListResponse.fromJson(Map<String, dynamic> json) {
    List<ApprovedProductModel> productList = [];

    if (json['data'] != null && json['data'] is List) {
      productList = (json['data'] as List)
          .map((e) => ApprovedProductModel.fromJson(e))
          .toList();
    }

    return ApprovedProductListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: productList,
    );
  }
}

class ProductReferralResponse {
  final bool status;
  final int productId;
  final String productName;
  final String slug;
  final String referralCode;
  final String referralLink;
  final String message;

  ProductReferralResponse({
    required this.status,
    required this.productId,
    required this.productName,
    required this.slug,
    required this.referralCode,
    required this.referralLink,
    required this.message,
  });

  factory ProductReferralResponse.fromJson(Map<String, dynamic> json) {
    return ProductReferralResponse(
      status: json['status'] ?? false,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      slug: json['slug'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
      message: json['message'] ?? '',
    );
  }
}