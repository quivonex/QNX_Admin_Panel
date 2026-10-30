// lib/models/shiprocket/courier_rate_model.dart

// ===================== COURIER RATES REQUEST =====================

class CourierRatesRequest {
  final String orderId;

  CourierRatesRequest({required this.orderId});

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
    };
  }
}

// ===================== COURIER RATES RESPONSE =====================

class CourierRatesResponse {
  final bool success;
  final List<CourierRate> data;

  CourierRatesResponse({
    required this.success,
    required this.data,
  });

  factory CourierRatesResponse.fromJson(Map<String, dynamic> json) {
    return CourierRatesResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List?)
          ?.map((item) => CourierRate.fromJson(item))
          .toList() ?? [],
    );
  }
}

class CourierRate {
  final int courierId;
  final double rate;

  CourierRate({
    required this.courierId,
    required this.rate,
  });

  factory CourierRate.fromJson(Map<String, dynamic> json) {
    return CourierRate(
      courierId: json['courier_id'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}