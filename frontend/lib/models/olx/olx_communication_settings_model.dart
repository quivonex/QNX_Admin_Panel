// lib/models/olx/olx_communication_settings_model.dart

// ==================== COMMUNICATION SETTINGS DATA MODEL ====================
// ==================== COMMUNICATION SETTINGS DATA MODEL ====================
class OlxCommunicationSettingsData {
  final int id;
  final String chatMode;
  final String enquiryMode;
  final int freeChatLimit;
  final String freeChatPeriod;
  final int freeEnquiryLimit;
  final String freeEnquiryPeriod;
  final bool blockContactInfo;
  final bool blockPhoneNumbers;
  final bool blockEmails;
  final bool blockSocialHandles;
  final bool blockExternalLinks;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  OlxCommunicationSettingsData({
    required this.id,
    required this.chatMode,
    required this.enquiryMode,
    required this.freeChatLimit,
    required this.freeChatPeriod,
    required this.freeEnquiryLimit,
    required this.freeEnquiryPeriod,
    required this.blockContactInfo,
    required this.blockPhoneNumbers,
    required this.blockEmails,
    required this.blockSocialHandles,
    required this.blockExternalLinks,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory OlxCommunicationSettingsData.fromJson(Map<String, dynamic> json) {
    return OlxCommunicationSettingsData(
      id: json['id'] ?? 0,
      chatMode: json['chat_mode'] ?? 'free',
      enquiryMode: json['enquiry_mode'] ?? 'free',
      freeChatLimit: json['free_chat_limit'] ?? 0,
      freeChatPeriod: json['free_chat_period'] ?? 'daily',
      freeEnquiryLimit: json['free_enquiry_limit'] ?? 0,
      freeEnquiryPeriod: json['free_enquiry_period'] ?? 'daily',
      blockContactInfo: json['block_contact_info'] ?? false,
      blockPhoneNumbers: json['block_phone_numbers'] ?? false,
      blockEmails: json['block_emails'] ?? false,
      blockSocialHandles: json['block_social_handles'] ?? false,
      blockExternalLinks: json['block_external_links'] ?? false,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_mode': chatMode,
      'enquiry_mode': enquiryMode,
      'free_chat_limit': freeChatLimit,
      'free_chat_period': freeChatPeriod,
      'free_enquiry_limit': freeEnquiryLimit,
      'free_enquiry_period': freeEnquiryPeriod,
      'block_contact_info': blockContactInfo,
      'block_phone_numbers': blockPhoneNumbers,
      'block_emails': blockEmails,
      'block_social_handles': blockSocialHandles,
      'block_external_links': blockExternalLinks,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// ==================== DETAIL REQUEST MODEL ====================
class OlxCommunicationSettingsDetailRequest {
  // No parameters required - empty body
  Map<String, dynamic> toJson() => {};
}

// ==================== UPDATE REQUEST MODEL ====================
class OlxCommunicationSettingsUpdateRequest {
  final String chatMode;
  final String enquiryMode;
  final int freeChatLimit;
  final String freeChatPeriod;
  final int freeEnquiryLimit;
  final String freeEnquiryPeriod;
  final bool blockContactInfo;
  final bool blockPhoneNumbers;
  final bool blockEmails;
  final bool blockSocialHandles;
  final bool blockExternalLinks;
  final bool isActive;

  OlxCommunicationSettingsUpdateRequest({
    required this.chatMode,
    required this.enquiryMode,
    required this.freeChatLimit,
    required this.freeChatPeriod,
    required this.freeEnquiryLimit,
    required this.freeEnquiryPeriod,
    required this.blockContactInfo,
    required this.blockPhoneNumbers,
    required this.blockEmails,
    required this.blockSocialHandles,
    required this.blockExternalLinks,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'chat_mode': chatMode,
      'enquiry_mode': enquiryMode,
      'free_chat_limit': freeChatLimit,
      'free_chat_period': freeChatPeriod,
      'free_enquiry_limit': freeEnquiryLimit,
      'free_enquiry_period': freeEnquiryPeriod,
      'block_contact_info': blockContactInfo,
      'block_phone_numbers': blockPhoneNumbers,
      'block_emails': blockEmails,
      'block_social_handles': blockSocialHandles,
      'block_external_links': blockExternalLinks,
      'is_active': isActive,
    };
  }
}

// ==================== DETAIL RESPONSE MODEL ====================
class OlxCommunicationSettingsDetailResponse {
  final bool status;
  final String message;
  final OlxCommunicationSettingsData? data;

  OlxCommunicationSettingsDetailResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OlxCommunicationSettingsDetailResponse.fromJson(
      Map<String, dynamic> json) {
    // ✅ Support both "success" and "status" keys
    final bool isSuccess = json['success'] == true || json['status'] == true;
    return OlxCommunicationSettingsDetailResponse(
      status: isSuccess,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxCommunicationSettingsData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== UPDATE RESPONSE MODEL ====================
// ==================== UPDATE RESPONSE MODEL ====================
class OlxCommunicationSettingsUpdateResponse {
  final bool status;
  final String message;
  final OlxCommunicationSettingsData? data;

  OlxCommunicationSettingsUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OlxCommunicationSettingsUpdateResponse.fromJson(
      Map<String, dynamic> json) {
    // ✅ Support both "success" and "status" keys
    final bool isSuccess = json['success'] == true || json['status'] == true;
    return OlxCommunicationSettingsUpdateResponse(
      status: isSuccess,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxCommunicationSettingsData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== CONSTANTS ====================
class OlxCommunicationConstants {
  static const List<Map<String, String>> chatModeOptions = [
    {'value': 'free', 'label': 'Free'},
    {'value': 'free_with_limit', 'label': 'Free With Limit'},
    {'value': 'subscription_required', 'label': 'Subscription Required'},
    {'value': 'mixed', 'label': 'Free Allowance Then Subscription'},
  ];

  static const List<Map<String, String>> enquiryModeOptions = [
    {'value': 'free', 'label': 'Free'},
    {'value': 'free_with_limit', 'label': 'Free With Limit'},
    {'value': 'subscription_required', 'label': 'Subscription Required'},
    {'value': 'mixed', 'label': 'Free Allowance Then Subscription'},
  ];

  static const List<Map<String, String>> freePeriodOptions = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
  ];

  static String getModeLabel(String value) {
    final found = chatModeOptions.firstWhere(
          (e) => e['value'] == value,
      orElse: () => {'value': value, 'label': value},
    );
    return found['label'] ?? value;
  }

  static String getPeriodLabel(String value) {
    final found = freePeriodOptions.firstWhere(
          (e) => e['value'] == value,
      orElse: () => {'value': value, 'label': value},
    );
    return found['label'] ?? value;
  }
}