class Company {
  final int? id;
  final String? logo;
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String gstNumber;
  final String? logoS3Key;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final String companySlogan;
  final int farmRegistrationYear;
  final String registrationNo;
  final String companyPanNo;
  final List<String> multipleEmailIds;
  final List<String> contacts;
  final String websiteUrl;
  final Map<String, String> socialMediaAccounts;
  final String ianNo;
  final bool? isActive;
  final DateTime? createdAt;
  final String? referralCode;
  final String? marketingPartnerName;

  Company({
    this.id,
    this.logo,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.gstNumber,
    this.logoS3Key,
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
    required this.companySlogan,
    required this.farmRegistrationYear,
    required this.registrationNo,
    required this.companyPanNo,
    required this.multipleEmailIds,
    required this.contacts,
    required this.websiteUrl,
    required this.socialMediaAccounts,
    required this.ianNo,
    this.isActive,
    this.createdAt,
    this.referralCode,
    this.marketingPartnerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'owner_name': ownerName,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'gst_number': gstNumber,
      'state': state,
      'district': district,
      'taluka': taluka,
      'village': village,
      'pincode': pincode,
      'company_slogan': companySlogan,
      'farm_registration_year': farmRegistrationYear,
      'registration_no': registrationNo,
      'company_pan_no': companyPanNo,
      'multiple_email_ids': multipleEmailIds,
      'contacts': contacts,
      'website_url': websiteUrl,
      'social_media_accounts': socialMediaAccounts,
      'IAN_No': ianNo,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      logo: json['logo'],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gst_number'] ?? '',
      logoS3Key: json['logo_s3_key'],
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      taluka: json['taluka'] ?? '',
      village: json['village'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      companySlogan: json['company_slogan'] ?? '',
      farmRegistrationYear: json['farm_registration_year'] ?? 0,
      registrationNo: json['registration_no'] ?? '',
      companyPanNo: json['company_pan_no'] ?? '',
      multipleEmailIds: List<String>.from(json['multiple_email_ids'] ?? []),
      contacts: List<String>.from(json['contacts'] ?? []),
      websiteUrl: json['website_url'] ?? '',
      socialMediaAccounts: Map<String, String>.from(json['social_media_accounts'] ?? {}),
      referralCode: json['referral_code'],
      marketingPartnerName: json['marketing_partner_name'],
      ianNo: json['IAN_No'] ?? '',
      isActive: json['is_active'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}



class CompanyAllModel {
  final int id;
  final String? logo;
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String gstNumber;
  final String? logoS3Key;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final String companySlogan;
  final int farmRegistrationYear;
  final String registrationNo;
  final String companyPanNo;
  final List<dynamic> multipleEmailIds;
  final List<dynamic> contacts;
  final String websiteUrl;
  final Map<String, dynamic> socialMediaAccounts;
  final String ianNo;
  bool isActive;
  final String createdAt;
  final int user;
  final String? referralCode;           // ✅ NEW
  final String? marketingPartnerName;   // ✅ NEW

  CompanyAllModel({
    required this.id,
    required this.logo,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.gstNumber,
    required this.logoS3Key,
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
    required this.companySlogan,
    required this.farmRegistrationYear,
    required this.registrationNo,
    required this.companyPanNo,
    required this.multipleEmailIds,
    required this.contacts,
    required this.websiteUrl,
    required this.socialMediaAccounts,
    required this.ianNo,
    required this.isActive,
    required this.createdAt,
    required this.user,
    this.referralCode,
    this.marketingPartnerName,
  });

  factory CompanyAllModel.fromJson(Map<String, dynamic> json) {
    return CompanyAllModel(
      id: json['id'] ?? 0,
      logo: json['logo'],
      name: json['name'] ?? "",
      ownerName: json['owner_name'] ?? "",
      email: json['email'] ?? "",
      phoneNumber: json['phone_number'] ?? "",
      address: json['address'] ?? "",
      gstNumber: json['gst_number'] ?? "",
      logoS3Key: json['logo_s3_key'],
      state: json['state'] ?? "",
      district: json['district'] ?? "",
      taluka: json['taluka'] ?? "",
      village: json['village'] ?? "",
      pincode: json['pincode']?.toString() ?? "",
      companySlogan: json['company_slogan'] ?? "",
      farmRegistrationYear: json['farm_registration_year'] ?? 0,
      registrationNo: json['registration_no'] ?? "",
      companyPanNo: json['company_pan_no'] ?? "",
      multipleEmailIds: List<dynamic>.from(json['multiple_email_ids'] ?? []),
      contacts: List<dynamic>.from(json['contacts'] ?? []),
      websiteUrl: json['website_url'] ?? "",
      socialMediaAccounts: Map<String, dynamic>.from(json['social_media_accounts'] ?? {}),
      ianNo: json['IAN_No'] ?? "",
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? "",
      user: json['user'] ?? 0,
      referralCode: json['referral_code'],
      marketingPartnerName: json['marketing_partner_name'],
    );
  }
}

class CompanySoftDeleteModel {

  final int companyId;

  CompanySoftDeleteModel({
    required this.companyId,
  });

  Map<String, dynamic> toJson() {

    return {
      "company_id": companyId
    };

  }

}

class CompanyRestoreModel {

  final int companyId;

  CompanyRestoreModel({
    required this.companyId,
  });

  Map<String, dynamic> toJson() {

    return {
      "company_id": companyId
    };

  }

}







class LatestCompanyResponse {
  final bool status;
  final String message;
  final List<LatestCompany> data;

  LatestCompanyResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LatestCompanyResponse.fromJson(Map<String, dynamic> json) {
    return LatestCompanyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((item) => LatestCompany.fromJson(item))
          .toList(),
    );
  }
}

class LatestCompany {
  final int id;
  final String? logoS3Key;
  final String name;
  final String ownerName;

  LatestCompany({
    required this.id,
    this.logoS3Key,
    required this.name,
    required this.ownerName,
  });

  factory LatestCompany.fromJson(Map<String, dynamic> json) {
    return LatestCompany(
      id: json['id'] ?? 0,
      logoS3Key: json['logo_s3_key'],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
    );
  }
}






class CompanyCountModel {
  final bool status;
  final String message;
  final int total;

  CompanyCountModel({
    required this.status,
    required this.message,
    required this.total,
  });

  factory CompanyCountModel.fromJson(Map<String, dynamic> json) {
    return CompanyCountModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}






class CompanySingleRetrieveResponse {
  final bool status;
  final String message;
  final CompanySingleRetrieveData data;

  CompanySingleRetrieveResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CompanySingleRetrieveResponse.fromJson(Map<String, dynamic> json) {
    return CompanySingleRetrieveResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: CompanySingleRetrieveData.fromJson(json['data'] ?? {}),
    );
  }
}

class CompanySingleRetrieveData {
  final int id;
  final String? logo;
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final String gstNumber;
  final String? logoS3Key;
  final String state;
  final String district;
  final String taluka;
  final String village;
  final String pincode;
  final String? shortDescription;
  final String? longDescription;
  final String companySlogan;
  final int farmRegistrationYear;
  final String registrationNo;
  final String companyPanNo;
  final List<String> multipleEmailIds;
  final List<String> contacts;
  final String? whatsappNo;
  final String websiteUrl;
  final String? facebookUrl;
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? privacyPolicyUrl;
  final String? termsConditionsUrl;
  final Map<String, String> socialMediaAccounts;
  final String ianNo;
  final bool isActive;
  final String createdAt;
  final String? referralCode;
  final String? marketingPartnerName;
  final int user;

  CompanySingleRetrieveData({
    required this.id,
    this.logo,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.gstNumber,
    this.logoS3Key,
    required this.state,
    required this.district,
    required this.taluka,
    required this.village,
    required this.pincode,
    this.shortDescription,
    this.longDescription,
    required this.companySlogan,
    required this.farmRegistrationYear,
    required this.registrationNo,
    required this.companyPanNo,
    required this.multipleEmailIds,
    required this.contacts,
    this.whatsappNo,
    required this.websiteUrl,
    this.facebookUrl,
    this.linkedinUrl,
    this.instagramUrl,
    this.youtubeUrl,
    this.privacyPolicyUrl,
    this.termsConditionsUrl,
    required this.socialMediaAccounts,
    required this.ianNo,
    required this.isActive,
    required this.createdAt,
    this.referralCode,
    this.marketingPartnerName,
    required this.user,
  });

  factory CompanySingleRetrieveData.fromJson(Map<String, dynamic> json) {
    return CompanySingleRetrieveData(
      id: json['id'] ?? 0,
      logo: json['logo'],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gst_number'] ?? '',
      logoS3Key: json['logo_s3_key'],
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      taluka: json['taluka'] ?? '',
      village: json['village'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      shortDescription: json['short_description'],
      longDescription: json['long_description'],
      companySlogan: json['company_slogan'] ?? '',
      farmRegistrationYear: json['farm_registration_year'] ?? 0,
      registrationNo: json['registration_no'] ?? '',
      companyPanNo: json['company_pan_no'] ?? '',
      multipleEmailIds: List<String>.from(json['multiple_email_ids'] ?? []),
      contacts: List<String>.from(json['contacts'] ?? []),
      whatsappNo: json['whatsapp_no'],
      websiteUrl: json['website_url'] ?? '',
      facebookUrl: json['facebook_url'],
      linkedinUrl: json['linkedin_url'],
      instagramUrl: json['instagram_url'],
      youtubeUrl: json['youtube_url'],
      privacyPolicyUrl: json['privacy_policy_url'],
      termsConditionsUrl: json['terms_conditions_url'],
      socialMediaAccounts: Map<String, String>.from(json['social_media_accounts'] ?? {}),
      ianNo: json['IAN_No'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      referralCode: json['referral_code'],
      marketingPartnerName: json['marketing_partner_name'],
      user: json['user'] ?? 0,
    );
  }
}
