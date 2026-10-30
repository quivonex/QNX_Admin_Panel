class PartnerCompany {
  final int id;
  final String? logo;
  final List<dynamic> images; // can be List<String> or empty
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String? gstNumber;
  final String? logoS3Key;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final String? shortDescription;
  final String? longDescription;
  final String? companySlogan;
  final String? farmRegistrationYear;
  final String? registrationNo;
  final String? companyPanNo;
  final List<String> multipleEmailIds;
  final List<String> contacts;
  final String? whatsappNo;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final bool isActive;
  final String createdAt;
  final String? referralCode;
  final String? marketingPartnerName;
  final String? paymentStatus;
  final int user;

  PartnerCompany({
    required this.id,
    this.logo,
    required this.images,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.gstNumber,
    this.logoS3Key,
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
    this.shortDescription,
    this.longDescription,
    this.companySlogan,
    this.farmRegistrationYear,
    this.registrationNo,
    this.companyPanNo,
    required this.multipleEmailIds,
    required this.contacts,
    this.whatsappNo,
    this.websiteUrl,
    this.facebookUrl,
    this.linkedinUrl,
    this.instagramUrl,
    this.youtubeUrl,
    required this.isActive,
    required this.createdAt,
    this.referralCode,
    this.marketingPartnerName,
    this.paymentStatus,
    required this.user,
  });

  factory PartnerCompany.fromJson(Map<String, dynamic> json) {
    return PartnerCompany(
      id: json['id'] ?? 0,
      logo: json['logo'],
      images: json['images'] ?? [],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gst_number'],
      logoS3Key: json['logo_s3_key'],
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      taluka: json['taluka'] ?? '',
      village: json['village'] ?? '',
      pincode: json['pincode'] ?? '',
      shortDescription: json['short_description'],
      longDescription: json['long_description'],
      companySlogan: json['company_slogan'],
      farmRegistrationYear: json['farm_registration_year'],
      registrationNo: json['registration_no'],
      companyPanNo: json['company_pan_no'],
      multipleEmailIds: (json['multiple_email_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contacts: (json['contacts'] as List?)?.map((e) => e.toString()).toList() ?? [],
      whatsappNo: json['whatsapp_no'],
      websiteUrl: json['website_url'],
      facebookUrl: json['facebook_url'],
      linkedinUrl: json['linkedin_url'],
      instagramUrl: json['instagram_url'],
      youtubeUrl: json['youtube_url'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      referralCode: json['referral_code'],
      marketingPartnerName: json['marketing_partner_name'],
      paymentStatus: json['payment_status'],
      user: json['user'] ?? 0,
    );
  }
}