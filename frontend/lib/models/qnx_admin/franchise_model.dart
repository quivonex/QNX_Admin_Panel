// lib/models/franchise_model.dart

class Franchise {
  final int id;
  final String companyName;
  final String franchiseCode;
  final String franchiseName;
  final String ownerName;
  final String email;
  final String mobileNo;
  final String? alternateMobileNo;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstNo;
  final String? panNo;
  final String commissionPercentage;
  final String joiningDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int company;
  final String? franchiseReferralCode;

  Franchise({
    required this.id,
    required this.companyName,
    required this.franchiseCode,
    required this.franchiseName,
    required this.ownerName,
    required this.email,
    required this.mobileNo,
    this.alternateMobileNo,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstNo,
    this.panNo,
    required this.commissionPercentage,
    this.franchiseReferralCode,
    required this.joiningDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.company,
  });

  factory Franchise.fromJson(Map<String, dynamic> json) {
    return Franchise(
      id: json['id'] ?? 0,
      companyName: json['company_name'] ?? '',
      franchiseCode: json['franchise_code'] ?? '',
      franchiseName: json['franchise_name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      alternateMobileNo: json['alternate_mobile_no']?.toString(),
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      gstNo: json['gst_no']?.toString(),
      panNo: json['pan_no']?.toString(),
      commissionPercentage: json['commission_percentage']?.toString() ?? '0',
      franchiseReferralCode: json['franchise_referral_code'],
      joiningDate: json['joining_date'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      company: json['company'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'franchise_code': franchiseCode,
      'franchise_name': franchiseName,
      'owner_name': ownerName,
      'email': email,
      'mobile_no': mobileNo,
      'alternate_mobile_no': alternateMobileNo,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gst_no': gstNo,
      'pan_no': panNo,
      'commission_percentage': commissionPercentage,
      'joining_date': joiningDate,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'company': company,
    };
  }

  // Helper method to get status badge color
  bool get isActive => status.toLowerCase() == 'active';

  // Helper method for display
  String get displayStatus {
    if (isActive) return 'Active';
    return 'Inactive';
  }
}