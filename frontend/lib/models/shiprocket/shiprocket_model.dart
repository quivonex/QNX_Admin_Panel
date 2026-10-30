// lib/models/shiprocket_model.dart

// ===================== REQUEST MODELS =====================

class ShiprocketCreateOrderRequest {
  final int orderId;

  ShiprocketCreateOrderRequest({required this.orderId});

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
    };
  }
}

// ===================== RESPONSE MODELS =====================

class ShipOrdersResponse {
  final bool success;
  final String message;
  final int count;
  final List<ShipOrder> data;

  ShipOrdersResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ShipOrdersResponse.fromJson(Map<String, dynamic> json) {
    return ShipOrdersResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
          ?.map((item) => ShipOrder.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ShipOrder {
  final int orderId;
  final String orderNumber;
  final ShipUser user;
  final ShipCompany company;
  final ShipProduct product;
  final ShipAddress address;
  final int quantity;
  final double price;
  final double subtotal;
  final double shippingCharge;
  final double tax;
  final double discount;
  final double totalAmount;
  final String paymentMethod;
  final bool paymentStatus;
  final String status;
  final String? notes;
  final String createdAt;

  ShipOrder({
    required this.orderId,
    required this.orderNumber,
    required this.user,
    required this.company,
    required this.product,
    required this.address,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.shippingCharge,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory ShipOrder.fromJson(Map<String, dynamic> json) {
    return ShipOrder(
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      user: ShipUser.fromJson(json['user'] ?? {}),
      company: ShipCompany.fromJson(json['company'] ?? {}),
      product: ShipProduct.fromJson(json['product'] ?? {}),
      address: ShipAddress.fromJson(json['address'] ?? {}),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingCharge: (json['shipping_charge'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? false,
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ShipUser {
  final int id;
  final String name;
  final String email;

  ShipUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ShipUser.fromJson(Map<String, dynamic> json) {
    return ShipUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ShipCompany {
  final int id;
  final String name;

  ShipCompany({
    required this.id,
    required this.name,
  });

  factory ShipCompany.fromJson(Map<String, dynamic> json) {
    return ShipCompany(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ShipProduct {
  final int id;
  final String name;

  ShipProduct({
    required this.id,
    required this.name,
  });

  factory ShipProduct.fromJson(Map<String, dynamic> json) {
    return ShipProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class ShipAddress {
  final int id;
  final String pincode;

  ShipAddress({
    required this.id,
    required this.pincode,
  });

  factory ShipAddress.fromJson(Map<String, dynamic> json) {
    return ShipAddress(
      id: json['id'] ?? 0,
      pincode: json['pincode'] ?? '',
    );
  }
}

// ===================== CREATE ORDER RESPONSE =====================

class ShiprocketCreateOrderResponse {
  final bool success;
  final String message;
  final ShiprocketData? shiprocketResponse;

  ShiprocketCreateOrderResponse({
    required this.success,
    required this.message,
    this.shiprocketResponse,
  });

  factory ShiprocketCreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return ShiprocketCreateOrderResponse(
      success: json['success'] ?? false,
      message: json['shiprocket_response']?['message'] ?? '',
      shiprocketResponse: json['shiprocket_response'] != null
          ? ShiprocketData.fromJson(json['shiprocket_response'])
          : null,
    );
  }
}

class ShiprocketData {
  final int orderId;
  final String channelOrderId;
  final int shipmentId;
  final String status;
  final int statusCode;
  final int onboardingCompletedNow;
  final String awbCode;
  final String courierCompanyId;
  final String courierName;
  final bool newChannel;
  final String packagingBoxError;
  final String message;

  ShiprocketData({
    required this.orderId,
    required this.channelOrderId,
    required this.shipmentId,
    required this.status,
    required this.statusCode,
    required this.onboardingCompletedNow,
    required this.awbCode,
    required this.courierCompanyId,
    required this.courierName,
    required this.newChannel,
    required this.packagingBoxError,
    required this.message,
  });

  factory ShiprocketData.fromJson(Map<String, dynamic> json) {
    return ShiprocketData(
      orderId: json['order_id'] ?? 0,
      channelOrderId: json['channel_order_id'] ?? '',
      shipmentId: json['shipment_id'] ?? 0,
      status: json['status'] ?? '',
      statusCode: json['status_code'] ?? 0,
      onboardingCompletedNow: json['onboarding_completed_now'] ?? 0,
      awbCode: json['awb_code'] ?? '',
      courierCompanyId: json['courier_company_id'] ?? '',
      courierName: json['courier_name'] ?? '',
      newChannel: json['new_channel'] ?? false,
      packagingBoxError: json['packaging_box_error'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
