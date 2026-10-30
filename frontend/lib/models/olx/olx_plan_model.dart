// lib/models/olx/olx_plan_model.dart

// ==================== PLAN REQUEST ====================
class OlxPlanRequest {
  final String name;
  final int durationDays;
  final String? description;
  final bool isActive;

  OlxPlanRequest({
    required this.name,
    required this.durationDays,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration_days': durationDays,
      'description': description ?? '',
      'is_active': isActive,
    };
  }
}

// ==================== PLAN CREATE RESPONSE ====================
class OlxPlanCreateResponse {
  final bool success;
  final String message;
  final OlxPlanData? data;

  OlxPlanCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxPlanCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxPlanCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OlxPlanData.fromJson(json['data']) : null,
    );
  }
}

// ==================== PLAN DATA ====================
class OlxPlanData {
  final int id;
  final String name;
  final int durationDays;
  final String? description;

  OlxPlanData({
    required this.id,
    required this.name,
    required this.durationDays,
    this.description,
  });

  factory OlxPlanData.fromJson(Map<String, dynamic> json) {
    return OlxPlanData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      durationDays: json['duration_days'] ?? 0,
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OlxPlanData &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== PLAN LIST RESPONSE ====================
class OlxPlanListResponse {
  final bool success;
  final List<OlxPlanData> data;

  OlxPlanListResponse({
    required this.success,
    this.data = const [],
  });

  factory OlxPlanListResponse.fromJson(Map<String, dynamic> json) {
    return OlxPlanListResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OlxPlanData.fromJson(e))
          .toList() ??
          [],
    );
  }
}