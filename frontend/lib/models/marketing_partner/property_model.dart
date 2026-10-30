// lib/models/real_estate/property_model.dart

// ============================================================
// REQUEST MODEL
// ============================================================
import 'dart:convert';

class PropertyRequest {
  final int? agentId;
  final String? referralCode;
  final String? status;

  PropertyRequest({
    this.agentId,
    this.referralCode,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (agentId != null) 'agent_id': agentId,
      if (referralCode != null) 'referral_code': referralCode,
      if (status != null) 'status': status,
    };
  }
}

// ============================================================
// RESPONSE MODELS
// ============================================================
class PropertyResponse {
  final bool status;
  final String message;
  final int count;
  final List<PropertyData> data;

  PropertyResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PropertyResponse.fromJson(Map<String, dynamic> json) {
    List<PropertyData> propertyList = [];
    if (json['data'] != null && json['data'] is List) {
      propertyList = (json['data'] as List)
          .map((e) => PropertyData.fromJson(e))
          .toList();
    }

    return PropertyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: propertyList,
    );
  }
}

class PropertyData {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String transactionType;
  final String status;
  final String price;
  final String? pricePerSqft;
  final String? maintenanceCharge;
  final String? bookingAmount;
  final String? totalArea;
  final String? carpetArea;
  final String? builtUpArea;
  final String? plotArea;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int kitchens;
  final int totalFloors;
  final int? floorNumber;
  final int parkingCount;
  final String parkingType;
  final String city;
  final String area;
  final String address;
  final String? landmark;
  final String? pincode;
  final String? latitude;
  final String? longitude;
  final Map<String, dynamic>? features;
  final String ownerName;
  final String ownerContact;
  final String? ownerEmail;
  final int viewsCount;
  final int enquiryCount;
  final int favoriteCount;
  final String createdAt;
  final String updatedAt;
  final String? publishedAt;
  final String? expiryDate;
  final bool isFeatured;
  final bool isVerified;
  final bool isFurnished;
  final bool isNegotiable;
  final bool isAvailable;
  final String? referralCode;
  final String statusApprove;
  final int agent;
  final List<AmenityDetail>? amenityDetails;

  PropertyData({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.status,
    required this.price,
    this.pricePerSqft,
    this.maintenanceCharge,
    this.bookingAmount,
    this.totalArea,
    this.carpetArea,
    this.builtUpArea,
    this.plotArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.kitchens,
    required this.totalFloors,
    this.floorNumber,
    required this.parkingCount,
    required this.parkingType,
    required this.city,
    required this.area,
    required this.address,
    this.landmark,
    this.pincode,
    this.latitude,
    this.longitude,
    this.features,
    required this.ownerName,
    required this.ownerContact,
    this.ownerEmail,
    required this.viewsCount,
    required this.enquiryCount,
    required this.favoriteCount,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.expiryDate,
    required this.isFeatured,
    required this.isVerified,
    required this.isFurnished,
    required this.isNegotiable,
    required this.isAvailable,
    this.referralCode,
    required this.statusApprove,
    required this.agent,
    this.amenityDetails,
  });

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    List<AmenityDetail> amenities = [];
    if (json['amenity_details'] != null && json['amenity_details'] is List) {
      amenities = (json['amenity_details'] as List)
          .map((e) => AmenityDetail.fromJson(e))
          .toList();
    }

    return PropertyData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      price: json['price']?.toString() ?? '0',
      pricePerSqft: json['price_per_sqft']?.toString(),
      maintenanceCharge: json['maintenance_charge']?.toString(),
      bookingAmount: json['booking_amount']?.toString(),
      totalArea: json['total_area']?.toString(),
      carpetArea: json['carpet_area']?.toString(),
      builtUpArea: json['built_up_area']?.toString(),
      plotArea: json['plot_area']?.toString(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      balconies: json['balconies'] ?? 0,
      kitchens: json['kitchens'] ?? 0,
      totalFloors: json['total_floors'] ?? 0,
      floorNumber: json['floor_number'],
      parkingCount: json['parking_count'] ?? 0,
      parkingType: json['parking_type'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'],
      pincode: json['pincode']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      features: _parseFeatures(json['features']),
      ownerName: json['owner_name'] ?? '',
      ownerContact: json['owner_contact'] ?? '',
      ownerEmail: json['owner_email'],
      viewsCount: json['views_count'] ?? 0,
      enquiryCount: json['enquiry_count'] ?? 0,
      favoriteCount: json['favorite_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      publishedAt: json['published_at'],
      expiryDate: json['expiry_date'],
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isFurnished: json['is_furnished'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      isAvailable: json['is_available'] ?? false,
      referralCode: json['referral_code'],
      statusApprove: json['status_approve'] ?? '',
      agent: json['agent'] ?? 0,
      amenityDetails: amenities,
    );
  }
  static Map<String, dynamic>? _parseFeatures(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is String) {
      if (raw.trim().isEmpty) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print('❌ Failed to parse features JSON: $e');
      }
      return null;
    }

    return null;
  }


}

class AmenityDetail {
  final int id;
  final String name;
  final bool isActive;
  final String createdAt;

  AmenityDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory AmenityDetail.fromJson(Map<String, dynamic> json) {
    return AmenityDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}