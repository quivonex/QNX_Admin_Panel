// lib/models/real_estate/channel_partner_model.dart

class ChannelPartnerResponse {
  final bool success;
  final String message;
  final int count;
  final List<ChannelPartnerData> data;

  ChannelPartnerResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ChannelPartnerResponse.fromJson(Map<String, dynamic> json) {
    return ChannelPartnerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((e) => ChannelPartnerData.fromJson(e)).toList()
          : [],
    );
  }
}

class ChannelPartnerData {
  final int id;
  final int? user;
  final String name;
  final String companyName;
  final String mobile;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String cpCode;
  final String reraNumber;
  final String commissionPercentage;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  ChannelPartnerData({
    required this.id,
    this.user,
    required this.name,
    required this.companyName,
    required this.mobile,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.cpCode,
    required this.reraNumber,
    required this.commissionPercentage,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelPartnerData.fromJson(Map<String, dynamic> json) {
    return ChannelPartnerData(
      id: json['id'] ?? 0,
      user: json['user'],
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      cpCode: json['cp_code'] ?? '',
      reraNumber: json['rera_number'] ?? '',
      commissionPercentage: json['commission_percentage']?.toString() ?? '0',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}