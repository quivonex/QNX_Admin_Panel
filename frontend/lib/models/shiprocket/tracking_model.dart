// lib/models/shiprocket/tracking_model.dart

// ===================== TRACK SHIPMENT REQUEST =====================

class TrackShipmentRequest {
  final String shipmentId;

  TrackShipmentRequest({required this.shipmentId});

  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
    };
  }
}

// ===================== TRACK SHIPMENT RESPONSE =====================

class TrackShipmentResponse {
  final bool success;
  final String message;
  final TrackShipmentData? data;

  TrackShipmentResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory TrackShipmentResponse.fromJson(Map<String, dynamic> json) {
    return TrackShipmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? TrackShipmentData.fromJson(json['data'])
          : null,
    );
  }
}

class TrackShipmentData {
  final TrackingData? trackingData;

  TrackShipmentData({this.trackingData});

  factory TrackShipmentData.fromJson(Map<String, dynamic> json) {
    return TrackShipmentData(
      trackingData: json['tracking_data'] != null
          ? TrackingData.fromJson(json['tracking_data'])
          : null,
    );
  }
}

class TrackingData {
  final int trackStatus;
  final int shipmentStatus;
  final List<ShipmentTrack> shipmentTrack;
  final List<ShipmentTrackActivity> shipmentTrackActivities;
  final String? trackUrl;
  final String? etd;
  final String? qcResponse;
  final List<dynamic>? qcImgUrl;
  final bool isReturn;
  final String? orderTag;
  final NprData? npr;
  final NdrData? ndr;

  TrackingData({
    required this.trackStatus,
    required this.shipmentStatus,
    required this.shipmentTrack,
    required this.shipmentTrackActivities,
    this.trackUrl,
    this.etd,
    this.qcResponse,
    this.qcImgUrl,
    required this.isReturn,
    this.orderTag,
    this.npr,
    this.ndr,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      trackStatus: json['track_status'] ?? 0,
      shipmentStatus: json['shipment_status'] ?? 0,
      shipmentTrack: (json['shipment_track'] as List?)
          ?.map((item) => ShipmentTrack.fromJson(item))
          .toList() ??
          [],
      shipmentTrackActivities: (json['shipment_track_activities'] as List?)
          ?.map((item) => ShipmentTrackActivity.fromJson(item))
          .toList() ??
          [],
      trackUrl: json['track_url'],
      etd: json['etd'],
      qcResponse: json['qc_response'],
      qcImgUrl: json['qc_img_url'] as List?,
      isReturn: json['is_return'] ?? false,
      orderTag: json['order_tag'],
      npr: json['npr'] != null ? NprData.fromJson(json['npr']) : null,
      ndr: json['ndr'] != null ? NdrData.fromJson(json['ndr']) : null,
    );
  }
}

class ShipmentTrack {
  final int id;
  final String awbCode;
  final int courierCompanyId;
  final int shipmentId;
  final int orderId;
  final String? pickupDate;
  final String? deliveredDate;
  final String weight;
  final int packages;
  final String currentStatus;
  final int currentStatusId;
  final String? deliveredTo;
  final String destination;
  final String? consigneeName;
  final String origin;
  final CourierAgentDetails? courierAgentDetails;
  final String courierName;
  final String? edd;
  final String? pod;
  final String? podStatus;
  final String? rtoDeliveredDate;
  final String? returnAwbCode;
  final String? updatedTimeStamp;

  ShipmentTrack({
    required this.id,
    required this.awbCode,
    required this.courierCompanyId,
    required this.shipmentId,
    required this.orderId,
    this.pickupDate,
    this.deliveredDate,
    required this.weight,
    required this.packages,
    required this.currentStatus,
    required this.currentStatusId,
    this.deliveredTo,
    required this.destination,
    this.consigneeName,
    required this.origin,
    this.courierAgentDetails,
    required this.courierName,
    this.edd,
    this.pod,
    this.podStatus,
    this.rtoDeliveredDate,
    this.returnAwbCode,
    this.updatedTimeStamp,
  });

  factory ShipmentTrack.fromJson(Map<String, dynamic> json) {
    return ShipmentTrack(
      id: json['id'] ?? 0,
      awbCode: json['awb_code'] ?? '',
      courierCompanyId: json['courier_company_id'] ?? 0,
      shipmentId: json['shipment_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      pickupDate: json['pickup_date'],
      deliveredDate: json['delivered_date'],
      weight: json['weight'] ?? '0',
      packages: json['packages'] ?? 0,
      currentStatus: json['current_status'] ?? '',
      currentStatusId: json['current_status_id'] ?? 0,
      deliveredTo: json['delivered_to'],
      destination: json['destination'] ?? '',
      consigneeName: json['consignee_name'],
      origin: json['origin'] ?? '',
      courierAgentDetails: json['courier_agent_details'] != null
          ? CourierAgentDetails.fromJson(json['courier_agent_details'])
          : null,
      courierName: json['courier_name'] ?? '',
      edd: json['edd'],
      pod: json['pod'],
      podStatus: json['pod_status'],
      rtoDeliveredDate: json['rto_delivered_date'],
      returnAwbCode: json['return_awb_code'],
      updatedTimeStamp: json['updated_time_stamp'],
    );
  }
}

class CourierAgentDetails {
  final String name;
  final String? phone;
  final int trackingStatus;

  CourierAgentDetails({
    required this.name,
    this.phone,
    required this.trackingStatus,
  });

  factory CourierAgentDetails.fromJson(Map<String, dynamic> json) {
    return CourierAgentDetails(
      name: json['name'] ?? '',
      phone: json['phone'],
      trackingStatus: json['tracking_status'] ?? 0,
    );
  }
}

class ShipmentTrackActivity {
  final String date;
  final String status;
  final String activity;
  final String location;
  final String srStatus;
  final String srStatusLabel;
  final String? latitude;
  final String? longitude;

  ShipmentTrackActivity({
    required this.date,
    required this.status,
    required this.activity,
    required this.location,
    required this.srStatus,
    required this.srStatusLabel,
    this.latitude,
    this.longitude,
  });

  factory ShipmentTrackActivity.fromJson(Map<String, dynamic> json) {
    return ShipmentTrackActivity(
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      activity: json['activity'] ?? '',
      location: json['location'] ?? '',
      srStatus: json['sr-status'] ?? '',
      srStatusLabel: json['sr-status-label'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

class NprData {
  final String reason;
  final String pickExceptionReasonCode;
  final int attempts;

  NprData({
    required this.reason,
    required this.pickExceptionReasonCode,
    required this.attempts,
  });

  factory NprData.fromJson(Map<String, dynamic> json) {
    return NprData(
      reason: json['reason'] ?? '',
      pickExceptionReasonCode: json['pick_exception_reason_code'] ?? '',
      attempts: json['attempts'] ?? 0,
    );
  }
}

class NdrData {
  final String reason;
  final String undeliveredReasonCode;
  final int attempts;

  NdrData({
    required this.reason,
    required this.undeliveredReasonCode,
    required this.attempts,
  });

  factory NdrData.fromJson(Map<String, dynamic> json) {
    return NdrData(
      reason: json['reason'] ?? '',
      undeliveredReasonCode: json['undelivered_reason_code'] ?? '',
      attempts: json['attempts'] ?? 0,
    );
  }
}