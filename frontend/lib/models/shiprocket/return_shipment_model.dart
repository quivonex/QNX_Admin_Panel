// lib/models/shiprocket/return_shipment_model.dart

// ==================== LIST RESPONSE ====================
class ReturnShipmentListResponse {
  final bool success;
  final String message;
  final int count;
  final List<ReturnShipment> data;

  ReturnShipmentListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ReturnShipmentListResponse.fromJson(Map<String, dynamic> json) {
    return ReturnShipmentListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ReturnShipment.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

// ==================== RETURN SHIPMENT ====================
class ReturnShipment {
  final int returnId;
  final String returnNumber;
  final int orderId;
  final String orderStatus;
  final String paymentMethod;
  final int productId;
  final String productName;
  final int quantity;
  final String reason;
  final String reasonNote;
  final double refundAmount;
  final String shiprocketOrderId;
  final String shipmentId;
  final String awbCode;
  final String courierCompany;
  final String status;
  final String createdAt;
  final String updatedAt;

  ReturnShipment({
    required this.returnId,
    required this.returnNumber,
    required this.orderId,
    required this.orderStatus,
    required this.paymentMethod,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.reasonNote,
    required this.refundAmount,
    required this.shiprocketOrderId,
    required this.shipmentId,
    required this.awbCode,
    required this.courierCompany,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ AWB assigned झालाय का ते check करा
  bool get hasAWB => awbCode.isNotEmpty && courierCompany.isNotEmpty;

  /// ✅ Shipment created झालाय का (shipment_id आहे)
  bool get hasShipment => shipmentId.isNotEmpty;

  factory ReturnShipment.fromJson(Map<String, dynamic> json) {
    return ReturnShipment(
      returnId: json['return_id'] ?? 0,
      returnNumber: json['return_number'] ?? '',
      orderId: json['order_id'] ?? 0,
      orderStatus: json['order_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      reason: json['reason'] ?? '',
      reasonNote: json['reason_note'] ?? '',
      refundAmount: _parseDouble(json['refund_amount']),
      shiprocketOrderId: json['shiprocket_order_id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      awbCode: json['awb_code']?.toString() ?? '',
      courierCompany: json['courier_company']?.toString() ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ==================== ASSIGN AWB REQUEST ====================
class AssignReturnAWBRequest {
  final String returnId;

  AssignReturnAWBRequest({required this.returnId});

  Map<String, dynamic> toJson() => {
    'return_id': returnId,
  };
}

// ==================== ASSIGN AWB RESPONSE ====================
class AssignReturnAWBResponse {
  final bool success;
  final String message;
  final AssignReturnAWBData? data;

  AssignReturnAWBResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AssignReturnAWBResponse.fromJson(Map<String, dynamic> json) {
    return AssignReturnAWBResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AssignReturnAWBData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AssignReturnAWBData {
  final int returnId;
  final String returnNumber;
  final String shipmentId;
  final String awbCode;
  final String courierCompany;
  final String status;

  AssignReturnAWBData({
    required this.returnId,
    required this.returnNumber,
    required this.shipmentId,
    required this.awbCode,
    required this.courierCompany,
    required this.status,
  });

  factory AssignReturnAWBData.fromJson(Map<String, dynamic> json) {
    return AssignReturnAWBData(
      returnId: json['return_id'] ?? 0,
      returnNumber: json['return_number'] ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      awbCode: json['awb_code']?.toString() ?? '',
      courierCompany: json['courier_company']?.toString() ?? '',
      status: json['status'] ?? '',
    );
  }
}