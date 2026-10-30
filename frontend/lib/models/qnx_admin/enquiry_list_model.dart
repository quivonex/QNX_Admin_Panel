class EnquiryListModel {
  int? id;
  String? personName;
  String? userType;
  String? shopName;
  String? firmName;
  String? companyName;
  List<String>? contacts;
  List<String>? emails;
  String? address;
  String? pincode;
  String? message;
  String? demoRequired;
  String? demoType;
  String? createdAt;

  EnquiryListModel({
    this.id,
    this.personName,
    this.userType,
    this.shopName,
    this.firmName,
    this.companyName,
    this.contacts,
    this.emails,
    this.address,
    this.pincode,
    this.message,
    this.demoRequired,
    this.demoType,
    this.createdAt,
  });

  factory EnquiryListModel.fromJson(Map<String, dynamic> json) {
    return EnquiryListModel(
      id: json['id'],
      personName: json['person_name'],
      userType: json['user_type'],
      shopName: json['shop_name'],
      firmName: json['firm_name'],
      companyName: json['company_name'],

      contacts: json['contacts'] != null
          ? List<String>.from(json['contacts'])
          : [],

      emails: json['emails'] != null
          ? List<String>.from(json['emails'])
          : [],

      address: json['address'],
      pincode: json['pincode'],
      message: json['message'],
      demoRequired: json['demo_required'],
      demoType: json['demo_type'],
      createdAt: json['created_at'],
    );
  }
}









class LatestEnquiryResponse {
  final bool status;
  final String message;
  final List<LatestEnquiry> data;

  LatestEnquiryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LatestEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return LatestEnquiryResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((item) => LatestEnquiry.fromJson(item))
          .toList(),
    );
  }
}

class LatestEnquiry {
  final int id;
  final String personName;
  final String shopName;
  final String companyName;

  LatestEnquiry({
    required this.id,
    required this.personName,
    required this.shopName,
    required this.companyName,
  });

  factory LatestEnquiry.fromJson(Map<String, dynamic> json) {
    return LatestEnquiry(
      id: json['id'] ?? 0,
      personName: json['person_name'] ?? '',
      shopName: json['shop_name'] ?? '',
      companyName: json['company_name'] ?? '',
    );
  }
}





class EnquiryCountModel {
  final bool status;
  final int count;

  EnquiryCountModel({
    required this.status,
    required this.count,
  });

  factory EnquiryCountModel.fromJson(Map<String, dynamic> json) {
    return EnquiryCountModel(
      status: json['status'] ?? false,
      count: json['count'] ?? 0,
    );
  }
}