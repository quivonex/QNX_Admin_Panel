// lib/models/olx/customer_subscription_plan_model.dart

// ==================== REQUEST MODEL ====================
class CustomerSubscriptionPlanRequest {
  final String name;
  final double price;
  final int enquiryLimit;
  final int durationDays;

  CustomerSubscriptionPlanRequest({
    required this.name,
    required this.price,
    required this.enquiryLimit,
    required this.durationDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'enquiry_limit': enquiryLimit,
      'duration_days': durationDays,
    };
  }
}

// ==================== RESPONSE MODELS ====================

// Single Plan Data Model
class CustomerSubscriptionPlanData {
  final int id;
  final String name;
  final String price;
  final int enquiryLimit;
  final int durationDays;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  CustomerSubscriptionPlanData({
    required this.id,
    required this.name,
    required this.price,
    required this.enquiryLimit,
    required this.durationDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerSubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return CustomerSubscriptionPlanData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      enquiryLimit: json['enquiry_limit'] ?? 0,
      durationDays: json['duration_days'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Helper to get price as double
  double get priceValue => double.tryParse(price) ?? 0.0;

  // Helper to get formatted price
  String get formattedPrice => '₹${priceValue.toStringAsFixed(2)}';
}

// Create Plan Response
class CustomerSubscriptionPlanCreateResponse {
  final bool success;
  final String message;
  final CustomerSubscriptionPlanData? data;

  CustomerSubscriptionPlanCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CustomerSubscriptionPlanCreateResponse.fromJson(
      Map<String, dynamic> json) {
    return CustomerSubscriptionPlanCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CustomerSubscriptionPlanData.fromJson(json['data'])
          : null,
    );
  }
}

// List Plans Response
class CustomerSubscriptionPlanListResponse {
  final bool success;
  final String message;
  final int count;
  final List<CustomerSubscriptionPlanData> data;

  CustomerSubscriptionPlanListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory CustomerSubscriptionPlanListResponse.fromJson(
      Map<String, dynamic> json) {
    return CustomerSubscriptionPlanListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CustomerSubscriptionPlanData.fromJson(e))
          .toList() ??
          [],
    );
  }
}