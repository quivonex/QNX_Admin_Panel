class SocialMediaAccounts {

  String? facebook;
  String? linkedin;
  String? instagram;

  SocialMediaAccounts({
    this.facebook,
    this.linkedin,
    this.instagram,
  });

  factory SocialMediaAccounts.fromJson(Map<String, dynamic> json) {

    return SocialMediaAccounts(
      facebook: json['facebook'],
      linkedin: json['linkedin'],
      instagram: json['instagram'],
    );
  }
}

class CompanyPendingModel {

  int? id;
  String? logo;
  String? name;
  String? ownerName;
  String? email;
  String? phoneNumber;
  String? address;
  String? gstNumber;
  String? logoS3Key;
  String? state;
  String? district;
  String? taluka;
  String? village;
  String? pincode;
  String? companySlogan;
  int? farmRegistrationYear;
  String? registrationNo;
  String? companyPanNo;
  List<String>? multipleEmailIds;
  List<String>? contacts;
  String? websiteUrl;
  SocialMediaAccounts? socialMediaAccounts;
  String? ianNo;
  bool? isVerified;
  bool? isActive;
  String? createdAt;
  int? user;

  CompanyPendingModel({

    this.id,
    this.logo,
    this.name,
    this.ownerName,
    this.email,
    this.phoneNumber,
    this.address,
    this.gstNumber,
    this.logoS3Key,
    this.state,
    this.district,
    this.taluka,
    this.village,
    this.pincode,
    this.companySlogan,
    this.farmRegistrationYear,
    this.registrationNo,
    this.companyPanNo,
    this.multipleEmailIds,
    this.contacts,
    this.websiteUrl,
    this.socialMediaAccounts,
    this.ianNo,
    this.isVerified,
    this.isActive,
    this.createdAt,
    this.user,
  });

  factory CompanyPendingModel.fromJson(Map<String, dynamic> json) {

    return CompanyPendingModel(

      id: json['id'],
      logo: json['logo'],
      name: json['name'],
      ownerName: json['owner_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      gstNumber: json['gst_number'],
      logoS3Key: json['logo_s3_key'],
      state: json['state'],
      district: json['district'],
      taluka: json['taluka'],
      village: json['village'],
      pincode: json['pincode'],
      companySlogan: json['company_slogan'],
      farmRegistrationYear: json['farm_registration_year'],
      registrationNo: json['registration_no'],
      companyPanNo: json['company_pan_no'],
      multipleEmailIds: List<String>.from(json['multiple_email_ids'] ?? []),
      contacts: List<String>.from(json['contacts'] ?? []),
      websiteUrl: json['website_url'],
      socialMediaAccounts: json['social_media_accounts'] != null
          ? SocialMediaAccounts.fromJson(json['social_media_accounts'])
          : null,
      ianNo: json['IAN_No'],
      isVerified: json['is_verified'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      user: json['user'],
    );
  }
}