// lib/models/marketing_head/referred_companies_model.dart

class ReferredCompaniesResponse {
  final bool status;
  final String marketingHead;
  final String marketingHeadReferralCode;
  final int totalPartners;
  final int totalCompanies;
  final List<PartnerData> data;

  ReferredCompaniesResponse({
    required this.status,
    required this.marketingHead,
    required this.marketingHeadReferralCode,
    required this.totalPartners,
    required this.totalCompanies,
    required this.data,
  });

  factory ReferredCompaniesResponse.fromJson(Map<String, dynamic> json) {
    return ReferredCompaniesResponse(
      status: json['status'] ?? false,
      marketingHead: json['marketing_head'] ?? '',
      marketingHeadReferralCode: json['marketing_head_referral_code'] ?? '',
      totalPartners: json['total_partners'] ?? 0,
      totalCompanies: json['total_companies'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PartnerData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class PartnerData {
  final int partnerId;
  final String partnerName;
  final String partnerEmail;
  final String partnerMobile;
  final String partnerReferralCode;
  final int totalCompanies;
  final List<CompanyData> companies;

  PartnerData({
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.partnerMobile,
    required this.partnerReferralCode,
    required this.totalCompanies,
    required this.companies,
  });

  factory PartnerData.fromJson(Map<String, dynamic> json) {
    return PartnerData(
      partnerId: json['partner_id'] ?? 0,
      partnerName: json['partner_name'] ?? '',
      partnerEmail: json['partner_email'] ?? '',
      partnerMobile: json['partner_mobile'] ?? '',
      partnerReferralCode: json['partner_referral_code'] ?? '',
      totalCompanies: json['total_companies'] ?? 0,
      companies: (json['companies'] as List<dynamic>?)
          ?.map((e) => CompanyData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class CompanyData {
  final int id;
  final String? logo;
  final List<dynamic> images;
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String? gstNumber;
  final String? state;
  final String? district;
  final String? taluka;
  final String? village;
  final String? pincode;
  final String? shortDescription;
  final String? longDescription;
  final String? companySlogan;
  final int? farmRegistrationYear;
  final String? registrationNo;
  final String? companyPanNo;
  final dynamic multipleEmailIds;
  final dynamic contacts;
  final String? whatsappNo;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final bool isActive;
  final String? createdAt;          // ✅ added
  final String? iANNo;              // ✅ added (maps to IAN_No)

  CompanyData({
    required this.id,
    this.logo,
    required this.images,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.gstNumber,
    this.state,
    this.district,
    this.taluka,
    this.village,
    this.pincode,
    this.shortDescription,
    this.longDescription,
    this.companySlogan,
    this.farmRegistrationYear,
    this.registrationNo,
    this.companyPanNo,
    this.multipleEmailIds,
    this.contacts,
    this.whatsappNo,
    this.websiteUrl,
    this.facebookUrl,
    this.linkedinUrl,
    this.instagramUrl,
    this.youtubeUrl,
    required this.isActive,
    this.createdAt,
    this.iANNo,
  });

  factory CompanyData.fromJson(Map<String, dynamic> json) {
    return CompanyData(
      id: json['id'] ?? 0,
      logo: json['logo'],
      images: json['images'] ?? [],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gst_number'],
      state: json['state'],
      district: json['district'],
      taluka: json['taluka'],
      village: json['village'],
      pincode: json['pincode']?.toString(),
      shortDescription: json['short_description'],
      longDescription: json['long_description'],
      companySlogan: json['company_slogan'],
      farmRegistrationYear: json['farm_registration_year'],
      registrationNo: json['registration_no'],
      companyPanNo: json['company_pan_no'],
      multipleEmailIds: json['multiple_email_ids'],
      contacts: json['contacts'],
      whatsappNo: json['whatsapp_no'],
      websiteUrl: json['website_url'],
      facebookUrl: json['facebook_url'],
      linkedinUrl: json['linkedin_url'],
      instagramUrl: json['instagram_url'],
      youtubeUrl: json['youtube_url'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'],
      iANNo: json['IAN_No'],
    );
  }
}