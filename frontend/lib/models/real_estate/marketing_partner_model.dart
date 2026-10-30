// lib/models/real_estate/marketing_partner_model.dart

class MarketingPartnerResponse {
  final bool status;
  final String message;
  final int count;
  final List<MarketingPartnerData> data;

  MarketingPartnerResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MarketingPartnerResponse.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List)
          .map((e) => MarketingPartnerData.fromJson(e))
          .toList()
          : [],
    );
  }
}

class MarketingPartnerData {
  final int id;
  final String referralCode;
  final String referralLink;
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
  final String createdAt;
  final int user;
  final int? referredBy;

  MarketingPartnerData({
    required this.id,
    required this.referralCode,
    required this.referralLink,
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
    required this.createdAt,
    required this.user,
    this.referredBy,
  });

  /// ✅ Display name for dropdown
  String get displayName => fullName.isNotEmpty ? fullName : email;

  /// ✅ Short info line for dropdown subtitle
  String get displaySubtitle =>
      '${profession.isNotEmpty ? profession : 'Marketing Partner'} • $referralCode';

  factory MarketingPartnerData.fromJson(Map<String, dynamic> json) {
    return MarketingPartnerData(
      id: json['id'] ?? 0,
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
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
      promotionPlatforms: json['promotion_platforms'] != null
          ? List<String>.from(json['promotion_platforms'])
          : [],
      teamSize: json['team_size'] ?? 1,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      user: json['user'] ?? 0,
      referredBy: json['referred_by'],
    );
  }
}