// lib/models/marketing_profile_model.dart

import 'package:flutter/foundation.dart';

class MarketingProfileResponse {
  final bool status;
  final String message;
  final String applicationType;
  final MarketingProfile data;

  MarketingProfileResponse({
    required this.status,
    required this.message,
    required this.applicationType,
    required this.data,
  });

  factory MarketingProfileResponse.fromJson(Map<String, dynamic> json) {
    return MarketingProfileResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      applicationType: json['application_type'] ?? '',
      data: MarketingProfile.fromJson(json['data'] ?? {}),
    );
  }
}

class MarketingProfile {
  final int id;
  final String? referredByName;
  final String? referredByReferralCode;
  final String applicationType;
  final bool otpVerified;
  final String? fullName;
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
  final String referralCode; // ✅ हे field आहे
  final String? referralLink;
  final String createdAt;
  final int userId;
  final int? referredBy;

  MarketingProfile({
    required this.id,
    this.referredByName,
    this.referredByReferralCode,
    required this.applicationType,
    required this.otpVerified,
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
    this.referralLink,
    required this.createdAt,
    required this.userId,
    this.referredBy,
  });

  factory MarketingProfile.fromJson(Map<String, dynamic> json) {
    // ✅ Safely parse promotion platforms
    List<String> platforms = [];
    if (json['promotion_platforms'] != null) {
      if (json['promotion_platforms'] is List) {
        platforms = List<String>.from(json['promotion_platforms']);
      }
    }

    return MarketingProfile(
      id: json['id'] ?? 0,
      referredByName: json['referred_by_name'],
      referredByReferralCode: json['referred_by_referral_code'],
      applicationType: json['application_type'] ?? '',
      otpVerified: json['otp_verified'] ?? false,
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
      promotionPlatforms: platforms,
      teamSize: json['team_size'] ?? 0,
      status: json['status'] ?? '',
      referralCode: json['referral_code'] ?? '', // ✅ येथे येतो referral code
      referralLink: json['referral_link'],
      createdAt: json['created_at'] ?? '',
      userId: json['user'] ?? 0,
      referredBy: json['referred_by'],
    );
  }
}