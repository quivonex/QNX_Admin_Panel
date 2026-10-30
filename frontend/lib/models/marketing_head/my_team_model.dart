// lib/models/marketing_head/my_team_model.dart
class MyReferredPartnerResponse {
  final bool status;
  final String marketingHead;
  final String referralCode;
  final int count;
  final List<MyReferredPartner> data;

  MyReferredPartnerResponse({
    required this.status,
    required this.marketingHead,
    required this.referralCode,
    required this.count,
    required this.data,
  });

  factory MyReferredPartnerResponse.fromJson(Map<String, dynamic> json) {
    return MyReferredPartnerResponse(
      status: json['status'] ?? false,
      marketingHead: json['marketing_head'] ?? '',
      referralCode: json['referral_code'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List)
          .map((e) => MyReferredPartner.fromJson(e))
          .toList(),
    );
  }
}

class MyReferredPartner {
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
  final String referralLink;
  final String createdAt;
  final int user;
  final int referredBy;

  MyReferredPartner({
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
    required this.referralLink,
    required this.createdAt,
    required this.user,
    required this.referredBy,
  });

  factory MyReferredPartner.fromJson(Map<String, dynamic> json) {
    return MyReferredPartner(
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
      referralLink: json['referral_link'] ?? '',
      createdAt: json['created_at'] ?? '',
      user: json['user'] ?? 0,
      referredBy: json['referred_by'] ?? 0,
    );
  }
}