// lib/models/shiprocket/return_order_model.dart

// ==================== LIST RESPONSE ====================
class ReturnOrderListResponse {
  final bool success;
  final String message;
  final int count;
  final List<ReturnOrder> data;

  ReturnOrderListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ReturnOrderListResponse.fromJson(Map<String, dynamic> json) {
    return ReturnOrderListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ReturnOrder.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

// ==================== RETURN ORDER ====================
class ReturnOrder {
  final int returnId;
  final String returnNumber;
  final int orderId;
  final String orderNumber;
  final String product;
  final int quantity;
  final String reason;
  final String reasonNote;
  final double refundAmount;
  final String currency;
  final String upiId;
  final String status;
  final String orderStatus;
  final String createdAt;
  final String updatedAt;

  ReturnOrder({
    required this.returnId,
    required this.returnNumber,
    required this.orderId,
    required this.orderNumber,
    required this.product,
    required this.quantity,
    required this.reason,
    required this.reasonNote,
    required this.refundAmount,
    required this.currency,
    required this.upiId,
    required this.status,
    required this.orderStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Safe numeric parser — handles String, int, double, null
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  factory ReturnOrder.fromJson(Map<String, dynamic> json) {
    return ReturnOrder(
      returnId: json['return_id'] ?? 0,
      returnNumber: json['return_number']?.toString() ?? '',
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      product: json['product']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      reason: json['reason']?.toString() ?? '',
      reasonNote: json['reason_note']?.toString() ?? '',
      refundAmount: _parseDouble(json['refund_amount']),
      currency: json['currency']?.toString() ?? 'INR',
      upiId: json['upi_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderStatus: json['order_status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

// ==================== CREATE SHIPMENT REQUEST ====================
class CreateReturnShipmentRequest {
  final String returnId;

  CreateReturnShipmentRequest({required this.returnId});

  Map<String, dynamic> toJson() => {
    'return_id': returnId,
  };
}

// ==================== CREATE SHIPMENT RESPONSE ====================
class CreateReturnShipmentResponse {
  final bool success;
  final String message;
  final ReturnShipmentData? data;
  final ShiprocketReturnResponse? shiprocketResponse;

  CreateReturnShipmentResponse({
    required this.success,
    required this.message,
    this.data,
    this.shiprocketResponse,
  });

  factory CreateReturnShipmentResponse.fromJson(Map<String, dynamic> json) {
    return CreateReturnShipmentResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? ReturnShipmentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      shiprocketResponse: json['shiprocket_response'] != null
          ? ShiprocketReturnResponse.fromJson(
          json['shiprocket_response'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReturnShipmentData {
  final int returnId;
  final String returnNumber;
  final String shiprocketOrderId;
  final String shipmentId;
  final String awbCode;
  final String courierCompany;
  final String status;

  ReturnShipmentData({
    required this.returnId,
    required this.returnNumber,
    required this.shiprocketOrderId,
    required this.shipmentId,
    required this.awbCode,
    required this.courierCompany,
    required this.status,
  });

  factory ReturnShipmentData.fromJson(Map<String, dynamic> json) {
    return ReturnShipmentData(
      returnId: json['return_id'] ?? 0,
      returnNumber: json['return_number']?.toString() ?? '',
      shiprocketOrderId: json['shiprocket_order_id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      awbCode: json['awb_code']?.toString() ?? '',
      courierCompany: json['courier_company']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class ShiprocketReturnResponse {
  final int status;
  final ShiprocketReturnPayload? payload;

  ShiprocketReturnResponse({required this.status, this.payload});

  factory ShiprocketReturnResponse.fromJson(Map<String, dynamic> json) {
    return ShiprocketReturnResponse(
      status: json['status'] ?? 0,
      payload: json['payload'] != null
          ? ShiprocketReturnPayload.fromJson(
          json['payload'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ShiprocketReturnPayload {
  final int orderCreated;
  final int awbGenerated;
  final int pickupGenerated;
  final String? pickupScheduledDate;
  final int orderId;
  final int shipmentId;
  final String awbCode;
  final int courierCompanyId;
  final String courierName;
  final int appliedWeight;
  final int cod;
  final int isReturn;
  final String routingCode;
  final String channelOrderId;

  ShiprocketReturnPayload({
    required this.orderCreated,
    required this.awbGenerated,
    required this.pickupGenerated,
    this.pickupScheduledDate,
    required this.orderId,
    required this.shipmentId,
    required this.awbCode,
    required this.courierCompanyId,
    required this.courierName,
    required this.appliedWeight,
    required this.cod,
    required this.isReturn,
    required this.routingCode,
    required this.channelOrderId,
  });

  factory ShiprocketReturnPayload.fromJson(Map<String, dynamic> json) {
    return ShiprocketReturnPayload(
      orderCreated: json['order_created'] ?? 0,
      awbGenerated: json['awb_generated'] ?? 0,
      pickupGenerated: json['pickup_generated'] ?? 0,
      pickupScheduledDate: json['pickup_scheduled_date']?.toString(),
      orderId: json['order_id'] ?? 0,
      shipmentId: json['shipment_id'] ?? 0,
      awbCode: json['awb_code']?.toString() ?? '',
      courierCompanyId: json['courier_company_id'] ?? 0,
      courierName: json['courier_name']?.toString() ?? '',
      appliedWeight: json['applied_weight'] ?? 0,
      cod: json['cod'] ?? 0,
      isReturn: json['is_return'] ?? 0,
      routingCode: json['routing_code']?.toString() ?? '',
      channelOrderId: json['channel_order_id']?.toString() ?? '',
    );
  }
}