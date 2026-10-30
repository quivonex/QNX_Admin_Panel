// lib/models/olx/olx_pricing_model.dart

// ==================== PRICING REQUEST ====================
class OlxPricingRequest {
  final int categoryId;
  final int planId;
  final num price;
  final bool isActive;

  OlxPricingRequest({
    required this.categoryId,
    required this.planId,
    required this.price,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'plan_id': planId,
      'price': price,
      'is_active': isActive,
    };
  }
}

// ==================== PRICING CREATE RESPONSE ====================
class OlxPricingCreateResponse {
  final bool success;
  final String message;
  final OlxPricingData? data;

  OlxPricingCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxPricingCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxPricingCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OlxPricingData.fromJson(json['data']) : null,
    );
  }
}

// ==================== PRICING DATA ====================
class OlxPricingData {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String? categorySlug;
  final int planId;
  final String? planName;
  final int? durationDays;
  final String price;
  final bool isActive;

  OlxPricingData({
    required this.id,
    required this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.planId,
    this.planName,
    this.durationDays,
    required this.price,
    this.isActive = true,
  });

  factory OlxPricingData.fromJson(Map<String, dynamic> json) {
    return OlxPricingData(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      categorySlug: json['category_slug'],
      planId: json['plan_id'] ?? 0,
      planName: json['plan_name'],
      durationDays: json['duration_days'],
      price: json['price']?.toString() ?? '0',
      isActive: json['is_active'] ?? true,
    );
  }
}

// ==================== PRICING LIST REQUEST ====================
class OlxPricingListRequest {
  final int planId;

  OlxPricingListRequest({required this.planId});

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
    };
  }
}

// ==================== PRICING LIST RESPONSE ====================
class OlxPricingListResponse {
  final bool success;
  final String message;
  final OlxPlanInfo? plan;
  final int count;
  final List<OlxPricingData> data;

  OlxPricingListResponse({
    required this.success,
    required this.message,
    this.plan,
    this.count = 0,
    this.data = const [],
  });

  factory OlxPricingListResponse.fromJson(Map<String, dynamic> json) {
    return OlxPricingListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      plan: json['plan'] != null ? OlxPlanInfo.fromJson(json['plan']) : null,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OlxPricingData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// ==================== PLAN INFO ====================
class OlxPlanInfo {
  final int id;
  final String name;
  final int durationDays;
  final String? description;

  OlxPlanInfo({
    required this.id,
    required this.name,
    required this.durationDays,
    this.description,
  });

  factory OlxPlanInfo.fromJson(Map<String, dynamic> json) {
    return OlxPlanInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      durationDays: json['duration_days'] ?? 0,
      description: json['description'],
    );
  }
}