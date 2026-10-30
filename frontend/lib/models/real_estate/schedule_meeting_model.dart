// lib/models/real_estate/schedule_meeting_model.dart

// ==================== REQUEST MODEL ====================

class ScheduleMeetingRequest {
  final int enquiryId;
  final String meetingDate;
  final String meetingTime;
  final String meetingLocation;
  final String? meetingNotes;

  ScheduleMeetingRequest({
    required this.enquiryId,
    required this.meetingDate,
    required this.meetingTime,
    required this.meetingLocation,
    this.meetingNotes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'enquiry_id': enquiryId,
      'meeting_date': meetingDate,
      'meeting_time': meetingTime,
      'meeting_location': meetingLocation,
    };

    if (meetingNotes != null && meetingNotes!.isNotEmpty) {
      data['meeting_notes'] = meetingNotes;
    }

    return data;
  }
}

// ==================== RESPONSE MODEL ====================

class ScheduleMeetingResponse {
  final bool success;
  final String message;
  final MeetingData? meeting;
  final WhatsAppData? whatsapp;

  ScheduleMeetingResponse({
    required this.success,
    required this.message,
    this.meeting,
    this.whatsapp,
  });

  factory ScheduleMeetingResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleMeetingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      meeting: json['meeting'] != null
          ? MeetingData.fromJson(json['meeting'])
          : null,
      whatsapp: json['whatsapp'] != null
          ? WhatsAppData.fromJson(json['whatsapp'])
          : null,
    );
  }
}

class MeetingData {
  final int enquiryId;
  final CustomerInfo? customer;
  final PropertyInfo? property;
  final MeetingDetails? meeting;
  final String status;
  final String scheduledAt;

  MeetingData({
    required this.enquiryId,
    this.customer,
    this.property,
    this.meeting,
    required this.status,
    required this.scheduledAt,
  });

  factory MeetingData.fromJson(Map<String, dynamic> json) {
    return MeetingData(
      enquiryId: json['enquiry_id'] ?? 0,
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'])
          : null,
      property: json['property'] != null
          ? PropertyInfo.fromJson(json['property'])
          : null,
      meeting: json['meeting'] != null
          ? MeetingDetails.fromJson(json['meeting'])
          : null,
      status: json['status'] ?? '',
      scheduledAt: json['scheduled_at'] ?? '',
    );
  }
}

class CustomerInfo {
  final String name;
  final String email;
  final String mobile;

  CustomerInfo({
    required this.name,
    required this.email,
    required this.mobile,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }
}

class PropertyInfo {
  final int id;
  final String title;

  PropertyInfo({
    required this.id,
    required this.title,
  });

  factory PropertyInfo.fromJson(Map<String, dynamic> json) {
    return PropertyInfo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class MeetingDetails {
  final String date;
  final String time;
  final String location;
  final String? notes;

  MeetingDetails({
    required this.date,
    required this.time,
    required this.location,
    this.notes,
  });

  factory MeetingDetails.fromJson(Map<String, dynamic> json) {
    return MeetingDetails(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'],
    );
  }
}

class WhatsAppData {
  final bool success;
  final int? statusCode;
  final WhatsAppResponse? response;

  WhatsAppData({
    required this.success,
    this.statusCode,
    this.response,
  });

  factory WhatsAppData.fromJson(Map<String, dynamic> json) {
    return WhatsAppData(
      success: json['success'] ?? false,
      statusCode: json['status_code'],
      response: json['response'] != null
          ? WhatsAppResponse.fromJson(json['response'])
          : null,
    );
  }
}

class WhatsAppResponse {
  final bool result;
  final String? phoneNumber;
  final String? templateName;

  WhatsAppResponse({
    required this.result,
    this.phoneNumber,
    this.templateName,
  });

  factory WhatsAppResponse.fromJson(Map<String, dynamic> json) {
    return WhatsAppResponse(
      result: json['result'] ?? false,
      phoneNumber: json['phone_number'],
      templateName: json['template_name'],
    );
  }
}