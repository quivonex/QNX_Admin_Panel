// lib/models/shiprocket/prepaid_cancelled_order_model.dart

// ==================== REQUEST MODEL ====================
class PrepaidCancelledOrdersRequest {
  // POST with empty body (server returns all prepaid cancelled orders)
  const PrepaidCancelledOrdersRequest();

  Map<String, dynamic> toJson() => {};
}

// ==================== LIST RESPONSE ====================
class PrepaidCancelledOrdersResponse {
  final bool success;
  final String message;
  final int count;
  final List<PrepaidCancelledOrder> data;

  PrepaidCancelledOrdersResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PrepaidCancelledOrdersResponse.fromJson(Map<String, dynamic> json) {
    return PrepaidCancelledOrdersResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) =>
          PrepaidCancelledOrder.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

// ==================== SINGLE ORDER MODEL ====================
class PrepaidCancelledOrder {
  final int orderId;
  final String orderNumber;
  final int userId;
  final int companyId;
  final int productId;
  final String product;
  final int quantity;
  final String paymentMethod;
  final bool paymentStatus;
  final String upiId; // may be empty / null
  final double subtotal;
  final double shippingCharge;
  final double taxAmount;
  final double discountAmount;
  final double refundAmount;
  final String currency;
  final String status;
  final String source;
  final String notes;
  final String createdAt;
  final String updatedAt;

  PrepaidCancelledOrder({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.companyId,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.upiId,
    required this.subtotal,
    required this.shippingCharge,
    required this.taxAmount,
    required this.discountAmount,
    required this.refundAmount,
    required this.currency,
    required this.status,
    required this.source,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Safe numeric parser — String / num / null सर्व हाताळतो
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  /// ✅ Safe bool parser — true/false किंवा "true"/"false" किंवा 1/0
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  factory PrepaidCancelledOrder.fromJson(Map<String, dynamic> json) {
    return PrepaidCancelledOrder(
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      companyId: json['company_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      product: json['product']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: _parseBool(json['payment_status']),
      upiId: json['upi_id']?.toString() ?? '',
      subtotal: _parseDouble(json['subtotal']),
      shippingCharge: _parseDouble(json['shipping_charge']),
      taxAmount: _parseDouble(json['tax_amount']),
      discountAmount: _parseDouble(json['discount_amount']),
      refundAmount: _parseDouble(json['refund_amount']),
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}