// lib/models/real_estate/property_list_model.dart

import 'package:flutter/foundation.dart';

// ==================== PROPERTY LIST RESPONSE ====================
class PropertyListResponse {
  final bool status;
  final String message;
  final int count;
  final List<PropertyData> data;

  PropertyListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PropertyListResponse.fromJson(Map<String, dynamic> json) {
    return PropertyListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PropertyData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ==================== BUILDER DETAIL ====================
class BuilderDetail {
  final int id;
  final String name;
  final String? shortInfo;
  final String? logoS3Key;
  final String? website;
  final String? email;
  final String? phone;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  BuilderDetail({
    required this.id,
    required this.name,
    this.shortInfo,
    this.logoS3Key,
    this.website,
    this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuilderDetail.fromJson(Map<String, dynamic> json) {
    return BuilderDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      shortInfo: json['short_info'],
      logoS3Key: json['logo_s3_key'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

// ==================== AMENITY DETAIL ====================
class AmenityDetail {
  final int id;
  final String name;
  final String? icon;
  final bool isActive;
  final String createdAt;

  AmenityDetail({
    required this.id,
    required this.name,
    this.icon,
    required this.isActive,
    required this.createdAt,
  });

  factory AmenityDetail.fromJson(Map<String, dynamic> json) {
    return AmenityDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ==================== IMAGE DETAIL ====================
class ImageDetail {
  final int id;
  final String imageS3Key;
  final String? caption;
  final bool isPrimary;

  ImageDetail({
    required this.id,
    required this.imageS3Key,
    this.caption,
    required this.isPrimary,
  });

  factory ImageDetail.fromJson(Map<String, dynamic> json) {
    return ImageDetail(
      id: json['id'] ?? 0,
      imageS3Key: json['image_s3_key'] ?? '',
      caption: json['caption'],
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

// ==================== VIDEO DETAIL ====================
class VideoDetail {
  final int id;
  final String videoS3Key;
  final String? title;
  final bool isFeatured;

  VideoDetail({
    required this.id,
    required this.videoS3Key,
    this.title,
    required this.isFeatured,
  });

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      id: json['id'] ?? 0,
      videoS3Key: json['video_s3_key'] ?? '',
      title: json['title'],
      isFeatured: json['is_featured'] ?? false,
    );
  }
}

// ==================== DOCUMENT DETAIL ====================
class DocumentDetail {
  final int id;
  final String? documentS3Key;
  final String? documentName;
  final String? documentType;

  DocumentDetail({
    required this.id,
    this.documentS3Key,
    this.documentName,
    this.documentType,
  });

  factory DocumentDetail.fromJson(Map<String, dynamic> json) {
    return DocumentDetail(
      id: json['id'] ?? 0,
      documentS3Key: json['document_s3_key'],
      documentName: json['document_name'],
      documentType: json['document_type'],
    );
  }
}

// ==================== FLAT TYPE ====================
class FlatTypeDetail {
  final int id;
  final String flatType;
  final String? areaSqft;
  final String? carpetArea;
  final String? builtUpArea;
  final String? balconyArea;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int kitchens;
  final int parkingCount;
  final String? description;
  final bool isAvailable;

  FlatTypeDetail({
    required this.id,
    required this.flatType,
    this.areaSqft,
    this.carpetArea,
    this.builtUpArea,
    this.balconyArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.kitchens,
    required this.parkingCount,
    this.description,
    required this.isAvailable,
  });

  factory FlatTypeDetail.fromJson(Map<String, dynamic> json) {
    return FlatTypeDetail(
      id: json['id'] ?? 0,
      flatType: json['flat_type'] ?? '',
      areaSqft: json['area_sqft']?.toString(),
      carpetArea: json['carpet_area']?.toString(),
      builtUpArea: json['built_up_area']?.toString(),
      balconyArea: json['balcony_area']?.toString(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      balconies: json['balconies'] ?? 0,
      kitchens: json['kitchens'] ?? 0,
      parkingCount: json['parking_count'] ?? 0,
      description: json['description'],
      isAvailable: json['is_available'] ?? true,
    );
  }
}

// ==================== FLOOR DETAIL ====================
class FloorDetail {
  final int id;
  final int floorNumber;
  final String floorName;
  final int totalUnits;
  final int availableUnits;
  final String? expectedCompletionDate;

  FloorDetail({
    required this.id,
    required this.floorNumber,
    required this.floorName,
    required this.totalUnits,
    required this.availableUnits,
    this.expectedCompletionDate,
  });

  factory FloorDetail.fromJson(Map<String, dynamic> json) {
    return FloorDetail(
      id: json['id'] ?? 0,
      floorNumber: json['floor_number'] ?? 0,
      floorName: json['floor_name'] ?? '',
      totalUnits: json['total_units'] ?? 0,
      availableUnits: json['available_units'] ?? 0,
      expectedCompletionDate: json['expected_completion_date'],
    );
  }
}

// ==================== PRICING SLAB DETAIL ====================
class PricingSlabDetail {
  final int id;
  final int floor;
  final String flatType;
  final String basePrice;
  final String? pricePerSqft;
  final String? bookingAmount;
  final String? discountPercentage;
  final String? gstPercentage;
  final Map<String, dynamic>? paymentSchedule;
  final Map<String, dynamic>? additionalCharges;
  final bool isAvailable;

  PricingSlabDetail({
    required this.id,
    required this.floor,
    required this.flatType,
    required this.basePrice,
    this.pricePerSqft,
    this.bookingAmount,
    this.discountPercentage,
    this.gstPercentage,
    this.paymentSchedule,
    this.additionalCharges,
    required this.isAvailable,
  });

  factory PricingSlabDetail.fromJson(Map<String, dynamic> json) {
    return PricingSlabDetail(
      id: json['id'] ?? 0,
      floor: json['floor'] ?? 0,
      flatType: json['flat_type'] ?? '',
      basePrice: json['base_price']?.toString() ?? '',
      pricePerSqft: json['price_per_sqft']?.toString(),
      bookingAmount: json['booking_amount']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      gstPercentage: json['gst_percentage']?.toString(),
      paymentSchedule: json['payment_schedule'] is Map
          ? Map<String, dynamic>.from(json['payment_schedule'])
          : null,
      additionalCharges: json['additional_charges'] is Map
          ? Map<String, dynamic>.from(json['additional_charges'])
          : null,
      isAvailable: json['is_available'] ?? true,
    );
  }
}

// ==================== PROPERTY DATA (MAIN) ====================
class PropertyData {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String transactionType;
  final String status;
  final bool statusApproved;
  final String city;
  final String area;
  final String address;
  final String? landmark;
  final String? pincode;
  final String? latitude;
  final String? longitude;
  final String? googleLocationUrl;
  final String? totalArea;
  final String? plotArea;
  final int? totalFloors;
  final int? totalTowers;
  final BuilderDetail? builder;
  final List<AmenityDetail> amenities;
  final List<ImageDetail> images;
  final List<VideoDetail> videos;
  final List<DocumentDetail> documents;
  final String? reraNumber;
  final String? reraQrCode;
  final String? reraWebsite;
  final List<dynamic> reraAdditionalUrls;
  final String? propertyWebsiteUrl;
  final bool? isUnderConstruction;
  final String? possessionDate;
  final int? completionPercentage;
  final Map<String, dynamic>? features;
  final bool isFeatured;
  final bool isVerified;
  final bool isNegotiable;
  final String? referralCode;
  final List<FlatTypeDetail> flatTypes;
  final List<FloorDetail> floors;
  final List<PricingSlabDetail> pricingSlabs;
  final String createdAt;
  final String updatedAt;
  final String? publishedAt;
  final String? expiryDate;
  final String? source;                    // "admin" / "website"
  final int? freeDays;                     // free_days
  final String? freeExpiryDate;            // free_expiry_date
  final bool? subscriptionRequired;        // subscription_required
  final bool? subscriptionActive;          // subscription_active


  PropertyData({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.status,
    required this.statusApproved,
    required this.city,
    required this.area,
    required this.address,
    this.landmark,
    this.pincode,
    this.latitude,
    this.longitude,
    this.googleLocationUrl,
    this.totalArea,
    this.plotArea,
    this.totalFloors,
    this.totalTowers,
    this.builder,
    this.amenities = const [],
    this.images = const [],
    this.videos = const [],
    this.documents = const [],
    this.reraNumber,
    this.reraQrCode,
    this.reraWebsite,
    this.reraAdditionalUrls = const [],
    this.propertyWebsiteUrl,
    this.isUnderConstruction,
    this.possessionDate,
    this.completionPercentage,
    this.features,
    this.isFeatured = false,
    this.isVerified = false,
    this.isNegotiable = false,
    this.referralCode,
    this.flatTypes = const [],
    this.floors = const [],
    this.pricingSlabs = const [],
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.expiryDate,
    this.source,
    this.freeDays,
    this.freeExpiryDate,
    this.subscriptionRequired,
    this.subscriptionActive,
  });

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    return PropertyData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      statusApproved: json['status_approved'] ?? false,
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'],
      pincode: json['pincode']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      googleLocationUrl: json['google_location_url'],
      totalArea: json['total_area']?.toString(),
      plotArea: json['plot_area']?.toString(),
      totalFloors: json['total_floors'],
      totalTowers: json['total_towers'],
      builder: json['builder'] != null && json['builder'] is Map
          ? BuilderDetail.fromJson(Map<String, dynamic>.from(json['builder']))
          : null,
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => AmenityDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      images: (json['images'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => ImageDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => VideoDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => DocumentDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reraNumber: json['rera_number'],
      reraQrCode: json['rera_qr_code'],
      reraWebsite: json['rera_website'],
      reraAdditionalUrls: json['rera_additional_urls'] ?? [],
      propertyWebsiteUrl: json['property_website_url'],
      isUnderConstruction: json['is_under_construction'],
      possessionDate: json['possession_date'],
      completionPercentage: json['completion_percentage'],
      features: json['features'] is Map
          ? Map<String, dynamic>.from(json['features'])
          : null,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      referralCode: json['referral_code'],
      flatTypes: (json['flat_types'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => FlatTypeDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      floors: (json['floors'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => FloorDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pricingSlabs: (json['pricing_slabs'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => PricingSlabDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      publishedAt: json['published_at'],
      expiryDate: json['expiry_date'],
      source: json['source'],
      freeDays: json['free_days'],
      freeExpiryDate: json['free_expiry_date'],
      subscriptionRequired: json['subscription_required'],
      subscriptionActive: json['subscription_active'],
    );
  }

  // ✅ Helper to get display status
  String get displayStatus {
    if (statusApproved) return 'Approved';
    if (status == 'draft') return 'Draft';
    if (status == 'pending') return 'Pending';
    if (status == 'rejected') return 'Rejected';
    return 'Pending';
  }
}

// ==================== APPROVE MODELS ====================
class PropertyApproveRequest {
  final int id;

  PropertyApproveRequest({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

class PropertyApproveResponse {
  final bool status;
  final String message;

  PropertyApproveResponse({required this.status, required this.message});

  factory PropertyApproveResponse.fromJson(Map<String, dynamic> json) {
    return PropertyApproveResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }
}