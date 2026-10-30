class PartnerCompany {
  final int id;
  final String? logo;
  final String name;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? gstNumber;
  final String? state;
  final String? district;
  final String? taluka;
  final String? village;
  final String? pincode;
  final String? shortDescription;
  final String? createdAt;
  final String? referralCode;
  final String? marketingPartnerName;

  PartnerCompany({
    required this.id,
    this.logo,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.gstNumber,
    this.state,
    this.district,
    this.taluka,
    this.village,
    this.pincode,
    this.shortDescription,
    this.createdAt,
    this.referralCode,
    this.marketingPartnerName,
  });

  factory PartnerCompany.fromJson(Map<String, dynamic> json) {
    return PartnerCompany(
      id: json['id'] ?? 0,
      logo: json['logo'],
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      gstNumber: json['gst_number'],
      state: json['state'],
      district: json['district'],
      taluka: json['taluka'],
      village: json['village'],
      pincode: json['pincode'],
      shortDescription: json['short_description'],
      createdAt: json['created_at'],
      referralCode: json['referral_code'],
      marketingPartnerName: json['marketing_partner_name'],
    );
  }
}