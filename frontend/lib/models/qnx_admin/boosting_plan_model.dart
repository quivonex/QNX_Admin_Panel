// ============================================================
// REQUEST MODEL
// ============================================================
class BoostingPlanRequest {
  final String name;
  final int durationDays;
  final String price;
  final bool isActive;

  BoostingPlanRequest({
    required this.name,
    required this.durationDays,
    required this.price,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'duration_days': durationDays,
      'price': price,
      'is_active': isActive,
    };
  }
}

// ============================================================
// DATA MODEL (Single Plan)
// ============================================================
class BoostingPlanData {
  final int id;
  final String name;
  final int durationDays;
  final String price;
  final bool isActive;
  final String createdAt;

  BoostingPlanData({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });

  factory BoostingPlanData.fromJson(Map<String, dynamic> json) {
    return BoostingPlanData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      durationDays: json['duration_days'] ?? 0,
      price: json['price']?.toString() ?? '0',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Returns price with ₹ symbol, formatted (e.g. ₹1.00 → ₹1)
  String get formattedPrice {
    final parsed = double.tryParse(price) ?? 0;
    if (parsed == parsed.roundToDouble()) {
      return '₹${parsed.toInt()}';
    }
    return '₹${parsed.toStringAsFixed(2)}';
  }

  /// Returns human readable validity (e.g. "7 days", "1 month")
  String get validityLabel {
    if (durationDays <= 0) return 'Not configured';
    if (durationDays % 365 == 0) {
      final y = durationDays ~/ 365;
      return '$y ${y == 1 ? 'year' : 'years'}';
    }
    if (durationDays % 30 == 0) {
      final m = durationDays ~/ 30;
      return '$m ${m == 1 ? 'month' : 'months'}';
    }
    if (durationDays % 7 == 0) {
      final w = durationDays ~/ 7;
      return '$w ${w == 1 ? 'week' : 'weeks'}';
    }
    return '$durationDays ${durationDays == 1 ? 'day' : 'days'}';
  }
}

// ============================================================
// CREATE RESPONSE (single object in data)
// ============================================================
class BoostingPlanCreateResponse {
  final bool success;
  final String message;
  final BoostingPlanData? data;

  BoostingPlanCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BoostingPlanCreateResponse.fromJson(Map<String, dynamic> json) {
    BoostingPlanData? planData;
    if (json['data'] is Map<String, dynamic>) {
      planData = BoostingPlanData.fromJson(json['data']);
    }
    return BoostingPlanCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: planData,
    );
  }
}

// ============================================================
// LIST RESPONSE (list in data)
// ============================================================
class BoostingPlanListResponse {
  final bool success;
  final String message;
  final int count;
  final List<BoostingPlanData> data;

  BoostingPlanListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory BoostingPlanListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final List<BoostingPlanData> plans = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          plans.add(BoostingPlanData.fromJson(item));
        }
      }
    }
    return BoostingPlanListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? plans.length,
      data: plans,
    );
  }
}