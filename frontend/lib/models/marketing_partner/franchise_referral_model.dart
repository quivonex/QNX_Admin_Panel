// lib/models/marketing_partner/franchise_referral_model.dart

import 'dart:convert';

// ============================================================
// FRANCHISE REFERRAL RESPONSE
// ============================================================
class FranchiseReferralResponse {
  final String status;
  final String message;
  final FranchiseReferralData? data;

  FranchiseReferralResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory FranchiseReferralResponse.fromJson(Map<String, dynamic> json) {
    return FranchiseReferralResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null
          ? FranchiseReferralData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class FranchiseReferralData {
  final String product;
  final String referralCode;
  final String referralLink;

  FranchiseReferralData({
    required this.product,
    required this.referralCode,
    required this.referralLink,
  });

  factory FranchiseReferralData.fromJson(Map<String, dynamic> json) {
    return FranchiseReferralData(
      product: json['product'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'referral_code': referralCode,
      'referral_link': referralLink,
    };
  }
}

// ============================================================
// FRANCHISE LIST MODEL - UPDATED AS PER API RESPONSE
// ============================================================
class FranchiseListModel {
  final int id;
  final String franchiseName;
  final String? companyName;
  final String? ownerName;
  final String? email;
  final String? mobileNo;
  final String? alternateMobileNo;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstNo;
  final String? panNo;
  final String? joiningDate;
  final String? status;
  final String? franchiseReferralCode;
  final String? createdAt;
  final String? updatedAt;
  final int? company;
  final int? product;
  final int? franchisePlan;

  FranchiseListModel({
    required this.id,
    required this.franchiseName,
    this.companyName,
    this.ownerName,
    this.email,
    this.mobileNo,
    this.alternateMobileNo,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstNo,
    this.panNo,
    this.joiningDate,
    this.status,
    this.franchiseReferralCode,
    this.createdAt,
    this.updatedAt,
    this.company,
    this.product,
    this.franchisePlan,
  });

  factory FranchiseListModel.fromJson(Map<String, dynamic> json) {
    return FranchiseListModel(
      id: json['id'] ?? 0,
      franchiseName: json['franchise_name'] ?? json['name'] ?? '',
      companyName: json['company_name'],
      ownerName: json['owner_name'],
      email: json['email'],
      mobileNo: json['mobile_no'],
      alternateMobileNo: json['alternate_mobile_no'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode']?.toString(),
      gstNo: json['gst_no'],
      panNo: json['pan_no'],
      joiningDate: json['joining_date'],
      status: json['status'] ?? 'active',
      franchiseReferralCode: json['franchise_referral_code'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      company: json['company'],
      product: json['product'],
      franchisePlan: json['FranchisePlan'],
    );
  }
}