// lib/models/real_estate/property_enquiry_model.dart

class PropertyEnquiryResponse {
  final bool success;
  final String message;
  final int count;
  final List<PropertyEnquiryData> data;

  PropertyEnquiryResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PropertyEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return PropertyEnquiryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((e) => PropertyEnquiryData.fromJson(e)).toList()
          : [],
    );
  }
}

class PropertyEnquiryData {
  final int id;
  final int property;
  final String customerName;
  final String customerEmail;
  final String customerMobile;
  final String message;
  final String status;
  final int? assignedChannelPartner;
  final String? assignedAt;
  final String? followupDate;
  final String createdAt;
  final String updatedAt;
  final PropertyDetails? propertyDetails;

  PropertyEnquiryData({
    required this.id,
    required this.property,
    required this.customerName,
    required this.customerEmail,
    required this.customerMobile,
    required this.message,
    required this.status,
    this.assignedChannelPartner,
    this.assignedAt,
    this.followupDate,
    required this.createdAt,
    required this.updatedAt,
    this.propertyDetails,
  });

  factory PropertyEnquiryData.fromJson(Map<String, dynamic> json) {
    return PropertyEnquiryData(
      id: json['id'] ?? 0,
      property: json['property'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      assignedChannelPartner: json['assigned_channel_partner'],
      assignedAt: json['assigned_at'],
      followupDate: json['followup_date'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      propertyDetails: json['property_details'] != null
          ? PropertyDetails.fromJson(json['property_details'])
          : null,
    );
  }
}

class PropertyDetails {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String transactionType;
  final String status;
  final String city;
  final String area;
  final String address;
  final String? landmark;
  final String? pincode;
  final String? latitude;
  final String? longitude;
  final String? totalArea;
  final String? plotArea;
  final int? totalFloors;
  final int? totalTowers;
  final int? builder;
  final int? agent;
  final String? reraNumber;
  final bool isUnderConstruction;
  final String? possessionDate;
  final int completionPercentage;
  final bool statusApproved;
  final bool isFeatured;
  final bool isVerified;
  final bool isNegotiable;
  final String? referralCode;
  final String createdAt;
  final String updatedAt;

  PropertyDetails({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.status,
    required this.city,
    required this.area,
    required this.address,
    this.landmark,
    this.pincode,
    this.latitude,
    this.longitude,
    this.totalArea,
    this.plotArea,
    this.totalFloors,
    this.totalTowers,
    this.builder,
    this.agent,
    this.reraNumber,
    required this.isUnderConstruction,
    this.possessionDate,
    required this.completionPercentage,
    required this.statusApproved,
    required this.isFeatured,
    required this.isVerified,
    required this.isNegotiable,
    this.referralCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'],
      pincode: json['pincode']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      totalArea: json['total_area']?.toString(),
      plotArea: json['plot_area']?.toString(),
      totalFloors: json['total_floors'],
      totalTowers: json['total_towers'],
      builder: json['builder'],
      agent: json['agent'],
      reraNumber: json['rera_number'],
      isUnderConstruction: json['is_under_construction'] ?? false,
      possessionDate: json['possession_date'],
      completionPercentage: json['completion_percentage'] ?? 0,
      statusApproved: json['status_approved'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      referralCode: json['referral_code'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}





// ==================== ASSIGN REQUEST/RESPONSE ====================
class PropertyEnquiryAssignRequest {
  final int enquiryId;
  final int channelPartnerId;

  PropertyEnquiryAssignRequest({
    required this.enquiryId,
    required this.channelPartnerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'enquiry_id': enquiryId,
      'channel_partner_id': channelPartnerId,
    };
  }
}

class PropertyEnquiryAssignResponse {
  final bool success;
  final String message;
  final AssignData? data;

  PropertyEnquiryAssignResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PropertyEnquiryAssignResponse.fromJson(Map<String, dynamic> json) {
    return PropertyEnquiryAssignResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AssignData.fromJson(json['data']) : null,
    );
  }
}

class AssignData {
  final int enquiryId;
  final int channelPartnerId;
  final String channelPartnerName;
  final String cpCode;
  final String status;
  final String assignedAt;

  AssignData({
    required this.enquiryId,
    required this.channelPartnerId,
    required this.channelPartnerName,
    required this.cpCode,
    required this.status,
    required this.assignedAt,
  });

  factory AssignData.fromJson(Map<String, dynamic> json) {
    return AssignData(
      enquiryId: json['enquiry_id'] ?? 0,
      channelPartnerId: json['channel_partner_id'] ?? 0,
      channelPartnerName: json['channel_partner_name'] ?? '',
      cpCode: json['cp_code'] ?? '',
      status: json['status'] ?? '',
      assignedAt: json['assigned_at'] ?? '',
    );
  }
}



// ==================== ENQUIRY-WISE MARKETING PARTNERS ====================
class EnquiryWiseMarketingPartnersResponse {
  final bool status;
  final String message;
  final int count;
  final int? defaultPartnerId;  // ✅ Property owner's partner ID (auto-select)
  final List<EnquiryWiseMarketingPartner> data;

  EnquiryWiseMarketingPartnersResponse({
    required this.status,
    required this.message,
    required this.count,
    this.defaultPartnerId,
    required this.data,
  });

  factory EnquiryWiseMarketingPartnersResponse.fromJson(
      Map<String, dynamic> json) {
    return EnquiryWiseMarketingPartnersResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      defaultPartnerId: json['default_partner_id'],  // ✅ Optional field
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) =>
          EnquiryWiseMarketingPartner.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EnquiryWiseMarketingPartner {
  final int id;
  final String? referralCode;
  final String? referralLink;
  final String? fullName;
  final String? email;
  final String? mobile;
  final String? profileImage;
  final String? profession;
  final String? status;

  EnquiryWiseMarketingPartner({
    required this.id,
    this.referralCode,
    this.referralLink,
    this.fullName,
    this.email,
    this.mobile,
    this.profileImage,
    this.profession,
    this.status,
  });

  /// ✅ Display name for checkbox list
  String get displayName => (fullName?.isNotEmpty ?? false)
      ? fullName!
      : (email?.isNotEmpty ?? false)
      ? email!
      : 'Partner #$id';

  /// ✅ Referral code — if missing, show first 3 letters of link + **
  String get displayReferralCode {
    if (referralCode != null && referralCode!.isNotEmpty) {
      // If it's a short code (no special chars), show it
      if (!referralCode!.contains('gAAAAA')) {
        return referralCode!;
      }
    }
    // Generate from link
    if (referralLink != null && referralLink!.isNotEmpty) {
      // Take first 3 letters of the referral link (after 'ref=')
      final link = referralLink!;
      String source = link;
      if (link.contains('ref=')) {
        source = link.split('ref=').last;
      }
      if (source.length >= 3) {
        return '${source.substring(0, 3)}**';
      } else if (source.isNotEmpty) {
        return '$source**';
      }
    }
    // Fallback
    return 'MP**';
  }

  factory EnquiryWiseMarketingPartner.fromJson(Map<String, dynamic> json) {
    return EnquiryWiseMarketingPartner(
      id: json['id'] ?? 0,
      referralCode: json['referral_code'],
      referralLink: json['referral_link'],
      fullName: json['full_name'],
      email: json['email'],
      mobile: json['mobile'],
      profileImage: json['profile_image'],
      profession: json['profession'],
      status: json['status'],
    );
  }
}