// lib/models/olx/olx_settings_model.dart

// ==================== SETTINGS DATA MODEL ====================
class OlxSettingsData {
  final int id;
  final bool firstListingFree;
  final int freeListingDays;
  final bool paymentRequiredAfterExpiry;
  final bool isActive;
  final String updatedAt;

  OlxSettingsData({
    required this.id,
    required this.firstListingFree,
    required this.freeListingDays,
    required this.paymentRequiredAfterExpiry,
    required this.isActive,
    required this.updatedAt,
  });

  factory OlxSettingsData.fromJson(Map<String, dynamic> json) {
    return OlxSettingsData(
      id: json['id'] ?? 0,
      firstListingFree: json['first_listing_free'] ?? false,
      freeListingDays: json['free_listing_days'] ?? 0,
      paymentRequiredAfterExpiry: json['payment_required_after_expiry'] ?? false,
      isActive: json['is_active'] ?? false,
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_listing_free': firstListingFree,
      'free_listing_days': freeListingDays,
      'payment_required_after_expiry': paymentRequiredAfterExpiry,
      'is_active': isActive,
      'updated_at': updatedAt,
    };
  }
}

// ==================== CREATE REQUEST MODEL ====================
class OlxSettingsCreateRequest {
  final bool firstListingFree;
  final int freeListingDays;
  final bool paymentRequiredAfterExpiry;
  final bool isActive;

  OlxSettingsCreateRequest({
    required this.firstListingFree,
    required this.freeListingDays,
    required this.paymentRequiredAfterExpiry,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_listing_free': firstListingFree,
      'free_listing_days': freeListingDays,
      'payment_required_after_expiry': paymentRequiredAfterExpiry,
      'is_active': isActive,
    };
  }
}

// ==================== UPDATE REQUEST MODEL ====================
class OlxSettingsUpdateRequest {
  final int id;
  final bool? firstListingFree;
  final int? freeListingDays;
  final bool? paymentRequiredAfterExpiry;
  final bool? isActive;

  OlxSettingsUpdateRequest({
    required this.id,
    this.firstListingFree,
    this.freeListingDays,
    this.paymentRequiredAfterExpiry,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'id': id};
    if (firstListingFree != null) data['first_listing_free'] = firstListingFree;
    if (freeListingDays != null) data['free_listing_days'] = freeListingDays;
    if (paymentRequiredAfterExpiry != null) {
      data['payment_required_after_expiry'] = paymentRequiredAfterExpiry;
    }
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

// ==================== GET REQUEST MODEL ====================
class OlxSettingsGetRequest {
  final int id;

  OlxSettingsGetRequest({required this.id});

  Map<String, dynamic> toJson() {
    return {'id': id};
  }
}

// ==================== CREATE RESPONSE MODEL ====================
class OlxSettingsCreateResponse {
  final bool success;
  final String message;
  final OlxSettingsData? data;

  OlxSettingsCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxSettingsCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxSettingsCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxSettingsData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== UPDATE RESPONSE MODEL ====================
class OlxSettingsUpdateResponse {
  final bool success;
  final String message;
  final OlxSettingsData? data;

  OlxSettingsUpdateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxSettingsUpdateResponse.fromJson(Map<String, dynamic> json) {
    return OlxSettingsUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxSettingsData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== GET RESPONSE MODEL ====================
class OlxSettingsListResponse {
  final bool success;
  final String message;
  final List<OlxSettingsData> data;

  OlxSettingsListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OlxSettingsListResponse.fromJson(Map<String, dynamic> json) {
    List<OlxSettingsData> settingsList = [];
    if (json['data'] != null && json['data'] is List) {
      settingsList = (json['data'] as List)
          .map((item) => OlxSettingsData.fromJson(item))
          .toList();
    }
    return OlxSettingsListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: settingsList,
    );
  }
}