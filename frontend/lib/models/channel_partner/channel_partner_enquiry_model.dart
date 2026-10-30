// lib/models/channel_partner/channel_partner_enquiry_model.dart

class ChannelPartnerEnquiryRequest {
  final String? status;
  final String? search;
  final int? page;
  final int? limit;

  ChannelPartnerEnquiryRequest({
    this.status,
    this.search,
    this.page,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (status != null && status!.isNotEmpty) data['status'] = status;
    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (page != null) data['page'] = page;
    if (limit != null) data['limit'] = limit;
    return data;
  }
}

class ChannelPartnerEnquiryResponse {
  final bool success;
  final String message;
  final ChannelPartnerInfo? channelPartner;
  final int count;
  final List<ChannelPartnerEnquiry> data;

  ChannelPartnerEnquiryResponse({
    required this.success,
    required this.message,
    this.channelPartner,
    required this.count,
    required this.data,
  });

  factory ChannelPartnerEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return ChannelPartnerEnquiryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      channelPartner: json['channel_partner'] != null
          ? ChannelPartnerInfo.fromJson(json['channel_partner'])
          : null,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => ChannelPartnerEnquiry.fromJson(e))
          .toList(),
    );
  }
}

class ChannelPartnerInfo {
  final int id;
  final String name;
  final String cpCode;

  ChannelPartnerInfo({
    required this.id,
    required this.name,
    required this.cpCode,
  });

  factory ChannelPartnerInfo.fromJson(Map<String, dynamic> json) {
    return ChannelPartnerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      cpCode: json['cp_code'] ?? '',
    );
  }
}

class ChannelPartnerEnquiry {
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

  ChannelPartnerEnquiry({
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

  factory ChannelPartnerEnquiry.fromJson(Map<String, dynamic> json) {
    return ChannelPartnerEnquiry(
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

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  String get formattedDateTime {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }
}

class PropertyDetails {
  final int id;
  final List<AmenityDetail> amenityDetails;
  final List<PropertyImage> images;
  final List<dynamic> videos;
  final List<dynamic> documents;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String transactionType;
  final String propertyCondition;
  final String status;
  final String city;
  final String area;
  final String address;
  final String landmark;
  final String pincode;
  final String? latitude;
  final String? longitude;
  final String? googleLocationUrl;
  final String? totalArea;
  final String? plotArea;
  final int totalFloors;
  final int totalTowers;
  final String? reraNumber;
  final String? reraWebsite;
  final String? propertyWebsiteUrl;
  final bool isUnderConstruction;
  final bool readyToMove;
  final String? possessionDate;
  final int completionPercentage;
  final dynamic features;
  final int viewsCount;
  final int enquiryCount;
  final int favoriteCount;
  final bool statusApproved;
  final bool isFeatured;
  final bool isVerified;
  final bool isNegotiable;
  final String? referralCode;
  final String createdAt;
  final String updatedAt;
  final int? builder;
  final int? agent;

  PropertyDetails({
    required this.id,
    required this.amenityDetails,
    required this.images,
    required this.videos,
    required this.documents,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.propertyCondition,
    required this.status,
    required this.city,
    required this.area,
    required this.address,
    required this.landmark,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.googleLocationUrl,
    this.totalArea,
    this.plotArea,
    required this.totalFloors,
    required this.totalTowers,
    this.reraNumber,
    this.reraWebsite,
    this.propertyWebsiteUrl,
    required this.isUnderConstruction,
    required this.readyToMove,
    this.possessionDate,
    required this.completionPercentage,
    this.features,
    required this.viewsCount,
    required this.enquiryCount,
    required this.favoriteCount,
    required this.statusApproved,
    required this.isFeatured,
    required this.isVerified,
    required this.isNegotiable,
    this.referralCode,
    required this.createdAt,
    required this.updatedAt,
    this.builder,
    this.agent,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      id: json['id'] ?? 0,
      amenityDetails: (json['amenity_details'] as List<dynamic>? ?? [])
          .map((e) => AmenityDetail.fromJson(e))
          .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => PropertyImage.fromJson(e))
          .toList(),
      videos: json['videos'] as List<dynamic>? ?? [],
      documents: json['documents'] as List<dynamic>? ?? [],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      propertyCondition: json['property_condition'] ?? '',
      status: json['status'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      googleLocationUrl: json['google_location_url'],
      totalArea: json['total_area'],
      plotArea: json['plot_area'],
      totalFloors: json['total_floors'] ?? 0,
      totalTowers: json['total_towers'] ?? 0,
      reraNumber: json['rera_number'],
      reraWebsite: json['rera_website'],
      propertyWebsiteUrl: json['property_website_url'],
      isUnderConstruction: json['is_under_construction'] ?? false,
      readyToMove: json['ready_to_move'] ?? false,
      possessionDate: json['possession_date'],
      completionPercentage: json['completion_percentage'] ?? 0,
      features: json['features'],
      viewsCount: json['views_count'] ?? 0,
      enquiryCount: json['enquiry_count'] ?? 0,
      favoriteCount: json['favorite_count'] ?? 0,
      statusApproved: json['status_approved'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      referralCode: json['referral_code'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      builder: json['builder'],
      agent: json['agent'],
    );
  }

  String get propertyTypeDisplay {
    switch (propertyType.toLowerCase()) {
      case 'flat':
        return 'Flat';
      case 'villa':
        return 'Villa';
      case 'plot':
        return 'Plot';
      case 'commercial':
        return 'Commercial';
      default:
        return propertyType.isNotEmpty
            ? propertyType[0].toUpperCase() + propertyType.substring(1)
            : '-';
    }
  }

  String get transactionTypeDisplay {
    switch (transactionType.toLowerCase()) {
      case 'sale':
        return 'Sale';
      case 'rent':
        return 'Rent';
      default:
        return transactionType.isNotEmpty
            ? transactionType[0].toUpperCase() + transactionType.substring(1)
            : '-';
    }
  }

  String get primaryImage {
    if (images.isEmpty) return '';
    try {
      return images.firstWhere((img) => img.isPrimary).imageS3Key;
    } catch (_) {
      return images.first.imageS3Key;
    }
  }
}

class AmenityDetail {
  final int id;
  final String name;
  final String icon;
  final bool isActive;
  final String createdAt;

  AmenityDetail({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.createdAt,
  });

  factory AmenityDetail.fromJson(Map<String, dynamic> json) {
    return AmenityDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PropertyImage {
  final int id;
  final String imageS3Key;
  final String caption;
  final bool isPrimary;

  PropertyImage({
    required this.id,
    required this.imageS3Key,
    required this.caption,
    required this.isPrimary,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'] ?? 0,
      imageS3Key: json['image_s3_key'] ?? '',
      caption: json['caption'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}