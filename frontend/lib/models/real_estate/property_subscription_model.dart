// lib/models/real_estate/property_subscription_model.dart

// ==================== REQUEST MODELS ====================

class PropertySubscriptionCreateRequest {
  final String name;
  final int days;
  final double price;

  PropertySubscriptionCreateRequest({
    required this.name,
    required this.days,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'days': days,
    'price': price,
  };
}

class PropertySubscriptionUpdateRequest {
  final int id;
  final String? name;
  final int? days;
  final double? price;
  final bool? isActive;

  PropertySubscriptionUpdateRequest({
    required this.id,
    this.name,
    this.days,
    this.price,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'id': id};
    if (name != null) data['name'] = name;
    if (days != null) data['days'] = days;
    if (price != null) data['price'] = price;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

// ==================== RESPONSE MODELS ====================

class PropertySubscriptionData {
  final int id;
  final String name;
  final int days;
  final double price;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  PropertySubscriptionData({
    required this.id,
    required this.name,
    required this.days,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertySubscriptionData.fromJson(Map<String, dynamic> json) {
    return PropertySubscriptionData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      days: json['days'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': days,
    'price': price,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class PropertySubscriptionCreateResponse {
  final bool success;
  final String message;
  final PropertySubscriptionData? data;

  PropertySubscriptionCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PropertySubscriptionCreateResponse.fromJson(Map<String, dynamic> json) {
    return PropertySubscriptionCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PropertySubscriptionData.fromJson(json['data'])
          : null,
    );
  }
}

class PropertySubscriptionListResponse {
  final bool success;
  final String message;
  final int count;
  final List<PropertySubscriptionData> data;

  PropertySubscriptionListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PropertySubscriptionListResponse.fromJson(Map<String, dynamic> json) {
    return PropertySubscriptionListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PropertySubscriptionData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class PropertySubscriptionUpdateResponse {
  final bool success;
  final String message;
  final PropertySubscriptionData? data;

  PropertySubscriptionUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PropertySubscriptionUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PropertySubscriptionUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PropertySubscriptionData.fromJson(json['data'])
          : null,
    );
  }
}