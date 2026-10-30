// lib/models/olx/olx_communication_plan_model.dart

// ==================== COMMUNICATION PLAN DATA MODEL ====================
class OlxCommunicationPlanData {
  final int id;
  final String name;
  final String description;
  final String price;
  final String currency;
  final int durationDays;
  final int chatLimit;
  final bool chatUnlimited;
  final String chatLimitPeriod;
  final int enquiryLimit;
  final bool enquiryUnlimited;
  final String enquiryLimitPeriod;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  OlxCommunicationPlanData({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.chatLimit,
    required this.chatUnlimited,
    required this.chatLimitPeriod,
    required this.enquiryLimit,
    required this.enquiryUnlimited,
    required this.enquiryLimitPeriod,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory OlxCommunicationPlanData.fromJson(Map<String, dynamic> json) {
    return OlxCommunicationPlanData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      currency: json['currency'] ?? 'INR',
      durationDays: json['duration_days'] ?? 0,
      chatLimit: json['chat_limit'] ?? 0,
      chatUnlimited: json['chat_unlimited'] ?? false,
      chatLimitPeriod: json['chat_limit_period'] ?? 'daily',
      enquiryLimit: json['enquiry_limit'] ?? 0,
      enquiryUnlimited: json['enquiry_unlimited'] ?? false,
      enquiryLimitPeriod: json['enquiry_limit_period'] ?? 'daily',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_days': durationDays,
      'chat_limit': chatLimit,
      'chat_unlimited': chatUnlimited,
      'chat_limit_period': chatLimitPeriod,
      'enquiry_limit': enquiryLimit,
      'enquiry_unlimited': enquiryUnlimited,
      'enquiry_limit_period': enquiryLimitPeriod,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// ==================== CREATE REQUEST MODEL ====================
class OlxCommunicationPlanCreateRequest {
  final String name;
  final String description;
  final String price;
  final String currency;
  final int durationDays;
  final int chatLimit;
  final bool chatUnlimited;
  final String chatLimitPeriod;
  final int enquiryLimit;
  final bool enquiryUnlimited;
  final String enquiryLimitPeriod;
  final bool isActive;

  OlxCommunicationPlanCreateRequest({
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.chatLimit,
    required this.chatUnlimited,
    required this.chatLimitPeriod,
    required this.enquiryLimit,
    required this.enquiryUnlimited,
    required this.enquiryLimitPeriod,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_days': durationDays,
      'chat_limit': chatLimit,
      'chat_unlimited': chatUnlimited,
      'chat_limit_period': chatLimitPeriod,
      'enquiry_limit': enquiryLimit,
      'enquiry_unlimited': enquiryUnlimited,
      'enquiry_limit_period': enquiryLimitPeriod,
      'is_active': isActive,
    };
  }
}

// ==================== UPDATE REQUEST MODEL ====================
class OlxCommunicationPlanUpdateRequest {
  final int planId;
  final String? name;
  final String? description;
  final String? price;
  final String? currency;
  final int? durationDays;
  final int? chatLimit;
  final bool? chatUnlimited;
  final String? chatLimitPeriod;
  final int? enquiryLimit;
  final bool? enquiryUnlimited;
  final String? enquiryLimitPeriod;
  final bool? isActive;

  OlxCommunicationPlanUpdateRequest({
    required this.planId,
    this.name,
    this.description,
    this.price,
    this.currency,
    this.durationDays,
    this.chatLimit,
    this.chatUnlimited,
    this.chatLimitPeriod,
    this.enquiryLimit,
    this.enquiryUnlimited,
    this.enquiryLimitPeriod,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'plan_id': planId};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (currency != null) data['currency'] = currency;
    if (durationDays != null) data['duration_days'] = durationDays;
    if (chatLimit != null) data['chat_limit'] = chatLimit;
    if (chatUnlimited != null) data['chat_unlimited'] = chatUnlimited;
    if (chatLimitPeriod != null) data['chat_limit_period'] = chatLimitPeriod;
    if (enquiryLimit != null) data['enquiry_limit'] = enquiryLimit;
    if (enquiryUnlimited != null) data['enquiry_unlimited'] = enquiryUnlimited;
    if (enquiryLimitPeriod != null) data['enquiry_limit_period'] = enquiryLimitPeriod;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

// ==================== LIST REQUEST MODEL ====================
class OlxCommunicationPlanListRequest {
  final bool includeInactive;

  OlxCommunicationPlanListRequest({this.includeInactive = true});

  Map<String, dynamic> toJson() {
    return {'include_inactive': includeInactive};
  }
}

// ==================== CREATE RESPONSE MODEL ====================
class OlxCommunicationPlanCreateResponse {
  final bool status;
  final String message;
  final OlxCommunicationPlanData? data;

  OlxCommunicationPlanCreateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OlxCommunicationPlanCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxCommunicationPlanCreateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxCommunicationPlanData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== UPDATE RESPONSE MODEL ====================
class OlxCommunicationPlanUpdateResponse {
  final bool status;
  final String message;
  final OlxCommunicationPlanData? data;

  OlxCommunicationPlanUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OlxCommunicationPlanUpdateResponse.fromJson(Map<String, dynamic> json) {
    return OlxCommunicationPlanUpdateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxCommunicationPlanData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== LIST RESPONSE MODEL ====================
class OlxCommunicationPlanListResponse {
  final bool success;
  final int count;
  final List<OlxCommunicationPlanData> data;

  OlxCommunicationPlanListResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory OlxCommunicationPlanListResponse.fromJson(Map<String, dynamic> json) {
    List<OlxCommunicationPlanData> planList = [];
    if (json['data'] != null && json['data'] is List) {
      planList = (json['data'] as List)
          .map((item) => OlxCommunicationPlanData.fromJson(item))
          .toList();
    }
    return OlxCommunicationPlanListResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? planList.length,
      data: planList,
    );
  }
}