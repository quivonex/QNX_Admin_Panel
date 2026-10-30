// lib/models/marketing_head_model.dart
import 'package:flutter/foundation.dart';
import '../../api/api_response.dart';  // for SendOtpResponse, VerifyOtpResponse

class MarketingHeadListResponse {
  final bool status;
  final String message;
  final int count;
  final List<MarketingHead> data;

  MarketingHeadListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MarketingHeadListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return MarketingHeadListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: list.map((e) => MarketingHead.fromJson(e)).toList(),
    );
  }
}

class MarketingHead {
  final int id;
  final String fullName;
  final String email;
  final String mobile;
  final String? profileImage;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final String workingArea;
  final String profession;
  final String experience;
  final List<String> promotionPlatforms;
  final int teamSize;
  final String status;
  final String referralCode;
  final String referralLink;
  final String createdAt;
  String get name => fullName;

  MarketingHead({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    this.profileImage,
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
    required this.workingArea,
    required this.profession,
    required this.experience,
    required this.promotionPlatforms,
    required this.teamSize,
    required this.status,
    required this.referralCode,
    required this.referralLink,
    required this.createdAt,
  });

  factory MarketingHead.fromJson(Map<String, dynamic> json) {
    return MarketingHead(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      profileImage: json['profile_image'],
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      taluka: json['taluka'] ?? '',
      village: json['village'] ?? '',
      pincode: json['pincode'] ?? '',
      workingArea: json['working_area'] ?? '',
      profession: json['profession'] ?? '',
      experience: json['experience'] ?? '',
      promotionPlatforms: List<String>.from(json['promotion_platforms'] ?? []),
      teamSize: json['team_size'] ?? 0,
      status: json['status'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Unique to this module
class RejectPartnerResponse {
  final bool status;
  final String message;
  RejectPartnerResponse({required this.status, required this.message});
  factory RejectPartnerResponse.fromJson(Map<String, dynamic> json) {
    return RejectPartnerResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

// lib/models/marketing_head_model.dart

// lib/models/marketing_head_model.dart

class CompleteRegistrationResponse {
  final bool status;
  final String message;
  final Map<String, dynamic>? data; // Keep data for detailed error info

  CompleteRegistrationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CompleteRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] is Map ? json['data'] : null,
    );
  }
}