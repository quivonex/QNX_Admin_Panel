// lib/models/referral_partner_model.dart
import 'package:flutter/foundation.dart';

class ReferredPartnersResponse {
  final bool status;
  final String marketingHead;
  final String referralCode;
  final int count;
  final List<ReferredPartner> data;

  ReferredPartnersResponse({
    required this.status,
    required this.marketingHead,
    required this.referralCode,
    required this.count,
    required this.data,
  });

  factory ReferredPartnersResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return ReferredPartnersResponse(
      status: json['status'] ?? false,
      marketingHead: json['marketing_head'] ?? '',
      referralCode: json['referral_code'] ?? '',
      count: json['count'] ?? 0,
      data: list.map((e) => ReferredPartner.fromJson(e)).toList(),
    );
  }
}

class ReferredPartner {
  final int id;
  final String referredByName;
  final String referredByReferralCode;
  final String applicationType;
  final bool otpVerified;
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
  final String? referralLink;
  final String createdAt;
  final int? userId;
  final int? referredBy;

  ReferredPartner({
    required this.id,
    required this.referredByName,
    required this.referredByReferralCode,
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
    this.userId,
    this.referredBy,
  });

  factory ReferredPartner.fromJson(Map<String, dynamic> json) {
    return ReferredPartner(
      id: json['id'] ?? 0,
      referredByName: json['referred_by_name'] ?? '',
      referredByReferralCode: json['referred_by_referral_code'] ?? '',
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
      promotionPlatforms: List<String>.from(json['promotion_platforms'] ?? []),
      teamSize: json['team_size'] ?? 0,
      status: json['status'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'],
      createdAt: json['created_at'] ?? '',
      userId: json['user'],
      referredBy: json['referred_by'],
    );
  }
}