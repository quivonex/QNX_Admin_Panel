// lib/models/qnx_admin/subscription_plan_model.dart

// ==================== REQUEST ====================
class SubscriptionPlanRequest {
  final String name;
  final String price;
  final int enquiryLimit;
  final int durationDays;
  final bool isActive;

  SubscriptionPlanRequest({
    required this.name,
    required this.price,
    required this.enquiryLimit,
    required this.durationDays,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'enquiry_limit': enquiryLimit,
      'duration_days': durationDays,
      'is_active': isActive,
    };
  }
}

// ==================== DATA ====================
class SubscriptionPlanData {
  final int id;
  final String name;
  final String price;
  final int enquiryLimit;
  final int durationDays;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  SubscriptionPlanData({
    required this.id,
    required this.name,
    required this.price,
    required this.enquiryLimit,
    required this.durationDays,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      enquiryLimit: _asInt(json['enquiry_limit']),
      durationDays: _asInt(json['duration_days']),
      isActive: _asBool(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'active';
    }
    return false;
  }
}

// ==================== CREATE RESPONSE ====================
class SubscriptionPlanCreateResponse {
  final bool success;
  final String message;
  final SubscriptionPlanData? data;

  SubscriptionPlanCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SubscriptionPlanCreateResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanCreateResponse(
      success: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? SubscriptionPlanData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== LIST RESPONSE ====================
class SubscriptionPlanListResponse {
  final bool success;
  final String message;
  final int count;
  final List<SubscriptionPlanData> data;

  SubscriptionPlanListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory SubscriptionPlanListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List?) ?? const [];
    return SubscriptionPlanListResponse(
      success: json['status'] == true,
      message: json['message']?.toString() ?? '',
      count: _asInt(json['count']),
      data: list
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionPlanData.fromJson(e))
          .toList(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }
}