// lib/models/real_estate/property_referral_model.dart

import 'dart:convert';

// ============================================================
// REQUEST MODEL - Only needs referral_code
// ============================================================
class PropertyReferralRequest {
  final String referralCode;

  PropertyReferralRequest({
    required this.referralCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'referral_code': referralCode,
    };
  }
}

// ============================================================
// RESPONSE MODEL
// ============================================================
class PropertyReferralResponse {
  final bool status;
  final String message;
  final PropertyReferralData? data;

  PropertyReferralResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PropertyReferralResponse.fromJson(Map<String, dynamic> json) {
    return PropertyReferralResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PropertyReferralData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

// ============================================================
// DATA MODEL
// ============================================================
class PropertyReferralData {
  final String referralCode;
  final String referralLink;

  PropertyReferralData({
    required this.referralCode,
    required this.referralLink,
  });

  factory PropertyReferralData.fromJson(Map<String, dynamic> json) {
    return PropertyReferralData(
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referral_code': referralCode,
      'referral_link': referralLink,
    };
  }
}