// lib/models/shiprocket/shipment_model.dart

// ===================== SHIPMENT LIST RESPONSE =====================

class ShipmentListResponse {
  final bool success;
  final String message;
  final int count;
  final List<Shipment> data;

  ShipmentListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ShipmentListResponse.fromJson(Map<String, dynamic> json) {
    return ShipmentListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
          ?.map((item) => Shipment.fromJson(item))
          .toList() ?? [],
    );
  }
}

// lib/models/shiprocket/shipment_model.dart

class Shipment {
  final int id;
  final int order;
  final String orderNumber;
  final String shiprocketOrderId;
  final String shipmentId;  // ✅ Must be String
  final String awbCode;
  final String courierCompany;
  final String? trackingUrl;
  final String shippingCharge;
  final String? labelUrl;
  final String? pickupRequestId;
  final String pickupStatus;
  final dynamic trackingData;
  final String? manifestUrl;
  final String status;
  final String createdAt;
  final String updatedAt;

  Shipment({
    required this.id,
    required this.order,
    required this.orderNumber,
    required this.shiprocketOrderId,
    required this.shipmentId,
    required this.awbCode,
    required this.courierCompany,
    this.trackingUrl,
    required this.shippingCharge,
    this.labelUrl,
    this.pickupRequestId,
    required this.pickupStatus,
    this.trackingData,
    this.manifestUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    // ✅ CRITICAL FIX: Safely convert shipment_id to String
    final shipmentIdValue = json['shipment_id'];
    final String shipmentIdStr = shipmentIdValue?.toString() ?? '';

    return Shipment(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      shiprocketOrderId: json['shiprocket_order_id'] ?? '',
      shipmentId: shipmentIdStr,  // ✅ Use the converted value
      awbCode: json['awb_code'] ?? '',
      courierCompany: json['courier_company'] ?? '',
      trackingUrl: json['tracking_url'],
      shippingCharge: json['shipping_charge'] ?? '0.00',
      labelUrl: json['label_url'],
      pickupRequestId: json['pickup_request_id'],
      pickupStatus: json['pickup_status'] ?? 'Pending',
      trackingData: json['tracking_data'],
      manifestUrl: json['manifest_url'],
      status: json['status'] ?? 'NEW',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

// ===================== ASSIGN AWB REQUEST =====================

class AssignAWBRequest {
  final String shipmentId;
  // Removed courierId - only shipment_id is needed

  AssignAWBRequest({
    required this.shipmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
    };
  }
}

// ===================== ASSIGN AWB RESPONSE =====================

class AssignAWBResponse {
  final bool success;
  final String message;
  final AssignAWBData? data;

  AssignAWBResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AssignAWBResponse.fromJson(Map<String, dynamic> json) {
    return AssignAWBResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AssignAWBData.fromJson(json['data'])
          : null,
    );
  }
}

class AssignAWBData {
  final int awbAssignStatus;
  final AWBResponse response;
  final int noPickupPopup;
  final int quickPick;

  AssignAWBData({
    required this.awbAssignStatus,
    required this.response,
    required this.noPickupPopup,
    required this.quickPick,
  });

  factory AssignAWBData.fromJson(Map<String, dynamic> json) {
    return AssignAWBData(
      awbAssignStatus: json['awb_assign_status'] ?? 0,
      response: AWBResponse.fromJson(json['response'] ?? {}),
      noPickupPopup: json['no_pickup_popup'] ?? 0,
      quickPick: json['quick_pick'] ?? 0,
    );
  }
}

class AWBResponse {
  final AWBData data;

  AWBResponse({
    required this.data,
  });

  factory AWBResponse.fromJson(Map<String, dynamic> json) {
    return AWBResponse(
      data: AWBData.fromJson(json['data'] ?? {}),
    );
  }
}

class AWBData {
  final int courierCompanyId;
  final String awbCode;
  final int cod;
  final String orderId;
  final String shipmentId;
  final int awbCodeStatus;
  final AssignedDateTime assignedDateTime;
  final double appliedWeight;
  final int companyId;
  final String courierName;
  final String? childCourierName;
  final String courierBrandName;
  final double freightCharges;
  final String routingCode;
  final String? rtoRoutingCode;
  final String invoiceNo;
  final String transporterId;
  final String transporterName;
  final ShippedBy shippedBy;
  final String pickupScheduledDate;

  AWBData({
    required this.courierCompanyId,
    required this.awbCode,
    required this.cod,
    required this.orderId,
    required this.shipmentId,
    required this.awbCodeStatus,
    required this.assignedDateTime,
    required this.appliedWeight,
    required this.companyId,
    required this.courierName,
    this.childCourierName,
    required this.courierBrandName,
    required this.freightCharges,
    required this.routingCode,
    this.rtoRoutingCode,
    required this.invoiceNo,
    required this.transporterId,
    required this.transporterName,
    required this.shippedBy,
    required this.pickupScheduledDate,
  });

  factory AWBData.fromJson(Map<String, dynamic> json) {
    return AWBData(
      courierCompanyId: json['courier_company_id'] ?? 0,
      awbCode: json['awb_code'] ?? '',
      cod: json['cod'] ?? 0,
      orderId: json['order_id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      awbCodeStatus: json['awb_code_status'] ?? 0,
      assignedDateTime: AssignedDateTime.fromJson(json['assigned_date_time'] ?? {}),
      appliedWeight: (json['applied_weight'] ?? 0).toDouble(),
      companyId: json['company_id'] ?? 0,
      courierName: json['courier_name'] ?? '',
      childCourierName: json['child_courier_name'],
      courierBrandName: json['courier_brand_name'] ?? '',
      freightCharges: (json['freight_charges'] ?? 0).toDouble(),
      routingCode: json['routing_code'] ?? '',
      rtoRoutingCode: json['rto_routing_code'],
      invoiceNo: json['invoice_no'] ?? '',
      transporterId: json['transporter_id'] ?? '',
      transporterName: json['transporter_name'] ?? '',
      shippedBy: ShippedBy.fromJson(json['shipped_by'] ?? {}),
      pickupScheduledDate: json['pickup_scheduled_date'] ?? '',
    );
  }
}

class AssignedDateTime {
  final String date;
  final int timezoneType;
  final String timezone;

  AssignedDateTime({
    required this.date,
    required this.timezoneType,
    required this.timezone,
  });

  factory AssignedDateTime.fromJson(Map<String, dynamic> json) {
    return AssignedDateTime(
      date: json['date'] ?? '',
      timezoneType: json['timezone_type'] ?? 3,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
    );
  }
}

class ShippedBy {
  final String shipperCompanyName;
  final String shipperAddress1;
  final String shipperAddress2;
  final String shipperCity;
  final String shipperState;
  final String shipperCountry;
  final String shipperPostcode;
  final int shipperFirstMileActivated;
  final String shipperPhone;
  final String lat;
  final String long;
  final String shipperEmail;
  final ExtraInfo extraInfo;
  final String rtoCompanyName;
  final String rtoAddress1;
  final String rtoAddress2;
  final String rtoCity;
  final String rtoState;
  final String rtoCountry;
  final String rtoPostcode;
  final String rtoPhone;
  final String rtoEmail;

  ShippedBy({
    required this.shipperCompanyName,
    required this.shipperAddress1,
    required this.shipperAddress2,
    required this.shipperCity,
    required this.shipperState,
    required this.shipperCountry,
    required this.shipperPostcode,
    required this.shipperFirstMileActivated,
    required this.shipperPhone,
    required this.lat,
    required this.long,
    required this.shipperEmail,
    required this.extraInfo,
    required this.rtoCompanyName,
    required this.rtoAddress1,
    required this.rtoAddress2,
    required this.rtoCity,
    required this.rtoState,
    required this.rtoCountry,
    required this.rtoPostcode,
    required this.rtoPhone,
    required this.rtoEmail,
  });

  factory ShippedBy.fromJson(Map<String, dynamic> json) {
    return ShippedBy(
      shipperCompanyName: json['shipper_company_name'] ?? '',
      shipperAddress1: json['shipper_address_1'] ?? '',
      shipperAddress2: json['shipper_address_2'] ?? '',
      shipperCity: json['shipper_city'] ?? '',
      shipperState: json['shipper_state'] ?? '',
      shipperCountry: json['shipper_country'] ?? '',
      shipperPostcode: json['shipper_postcode'] ?? '',
      shipperFirstMileActivated: json['shipper_first_mile_activated'] ?? 0,
      shipperPhone: json['shipper_phone'] ?? '',
      lat: json['lat'] ?? '',
      long: json['long'] ?? '',
      shipperEmail: json['shipper_email'] ?? '',
      extraInfo: ExtraInfo.fromJson(json['extra_info'] ?? {}),
      rtoCompanyName: json['rto_company_name'] ?? '',
      rtoAddress1: json['rto_address_1'] ?? '',
      rtoAddress2: json['rto_address_2'] ?? '',
      rtoCity: json['rto_city'] ?? '',
      rtoState: json['rto_state'] ?? '',
      rtoCountry: json['rto_country'] ?? '',
      rtoPostcode: json['rto_postcode'] ?? '',
      rtoPhone: json['rto_phone'] ?? '',
      rtoEmail: json['rto_email'] ?? '',
    );
  }
}

class ExtraInfo {
  final String role;
  final int source;
  final String openTime;
  final String closeTime;
  final String selectDays;
  final String alternateName;
  final String alternateRole;
  final String alternateEmail;

  ExtraInfo({
    required this.role,
    required this.source,
    required this.openTime,
    required this.closeTime,
    required this.selectDays,
    required this.alternateName,
    required this.alternateRole,
    required this.alternateEmail,
  });

  factory ExtraInfo.fromJson(Map<String, dynamic> json) {
    return ExtraInfo(
      role: json['role'] ?? '',
      source: json['source'] ?? 1,
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
      selectDays: json['select_days'] ?? '',
      alternateName: json['alternate_name'] ?? '',
      alternateRole: json['alternate_role'] ?? '',
      alternateEmail: json['alternate_email'] ?? '',
    );
  }
}