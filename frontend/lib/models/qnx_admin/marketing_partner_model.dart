// lib/models/marketing_partner_model.dart
import 'package:flutter/foundation.dart';

class MarketingPartnerListResponse {
  final bool status;
  final String message;
  final int count;
  final List<MarketingPartner> data;

  MarketingPartnerListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MarketingPartnerListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return MarketingPartnerListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: list.map((e) => MarketingPartner.fromJson(e)).toList(),
    );
  }
}

class MarketingPartner {
  final int id;
  final String? referredByName;
  final String? referredByReferralCode;
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
  String get name => fullName;

  MarketingPartner({
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
    this.userId,
    this.referredBy,
  });

  factory MarketingPartner.fromJson(Map<String, dynamic> json) {
    return MarketingPartner(
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

// lib/models/marketing_partner_model.dart मध्ये MarketingPartner class मध्ये add करा

extension MarketingPartnerExtension on MarketingPartner {
  /// Generate unique username from email
  /// Converts email to username and adds suffix if needed
  String generateUsername() {
    // Email मधून @ पूर्वीचा भाग घ्या
    String baseUsername = email.split('@').first.toLowerCase();

    // Special characters remove करा
    baseUsername = baseUsername.replaceAll(RegExp(r'[^a-z0-9]'), '');

    // जर base username रिकामा असेल तर 'user' वापरा
    if (baseUsername.isEmpty) {
      baseUsername = 'user';
    }

    // जर username लहान असेल तर पूर्ण करा
    if (baseUsername.length < 3) {
      baseUsername = baseUsername.padRight(3, '0');
    }

    return baseUsername;
  }

  /// Generate username with random suffix for uniqueness
  String generateUniqueUsername({int randomLength = 3}) {
    String base = generateUsername();
    String suffix = '';

    // Generate random numeric suffix
    for (int i = 0; i < randomLength; i++) {
      suffix += (DateTime.now().millisecondsSinceEpoch % 10).toString();
      // Slight variation for randomness
      Future.delayed(Duration(microseconds: 1));
    }

    // Ensure suffix is not empty
    if (suffix.isEmpty) {
      suffix = DateTime.now().millisecond.toString().substring(0, 2);
    }

    return '$base$suffix';
  }
}
