// lib/models/real_estate/property_model.dart

import 'dart:typed_data';

// ==================== MEDIA FILE MODEL ====================
class MediaFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final int size;

  MediaFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
    required this.size,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';
}

// ==================== FLAT TYPE ====================
class FlatType {
  final String flatType;
  final String areaSqft;
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

  FlatType({
    required this.flatType,
    required this.areaSqft,
    this.carpetArea,
    this.builtUpArea,
    this.balconyArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.kitchens,
    required this.parkingCount,
    this.description,
    this.isAvailable = true,
  });

  factory FlatType.fromJson(Map<String, dynamic> json) {
    return FlatType(
      flatType: json['flat_type'] ?? '',
      areaSqft: json['area_sqft']?.toString() ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'flat_type': flatType,
      'area_sqft': areaSqft,
      if (carpetArea != null && carpetArea!.isNotEmpty) 'carpet_area': carpetArea,
      if (builtUpArea != null && builtUpArea!.isNotEmpty) 'built_up_area': builtUpArea,
      if (balconyArea != null && balconyArea!.isNotEmpty) 'balcony_area': balconyArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'balconies': balconies,
      'kitchens': kitchens,
      'parking_count': parkingCount,
      if (description != null && description!.isNotEmpty) 'description': description,
      'is_available': isAvailable,
    };
  }
}

// ==================== FLOOR ====================
class Floor {
  final int floorNumber;
  final String floorName;
  final int totalUnits;
  final int availableUnits;

  Floor({
    required this.floorNumber,
    required this.floorName,
    required this.totalUnits,
    required this.availableUnits,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      floorNumber: json['floor_number'] ?? 0,
      floorName: json['floor_name'] ?? '',
      totalUnits: json['total_units'] ?? 0,
      availableUnits: json['available_units'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floor_number': floorNumber,
      'floor_name': floorName,
      'total_units': totalUnits,
      'available_units': availableUnits,
    };
  }
}

// ==================== PRICING SLAB ====================
class PricingSlab {
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

  PricingSlab({
    required this.floor,
    required this.flatType,
    required this.basePrice,
    this.pricePerSqft,
    this.bookingAmount,
    this.discountPercentage,
    this.gstPercentage,
    this.paymentSchedule,
    this.additionalCharges,
    this.isAvailable = true,
  });

  factory PricingSlab.fromJson(Map<String, dynamic> json) {
    return PricingSlab(
      floor: json['floor'] ?? 0,
      flatType: json['flat_type'] ?? '',
      basePrice: json['base_price']?.toString() ?? '',
      pricePerSqft: json['price_per_sqft']?.toString(),
      bookingAmount: json['booking_amount']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      gstPercentage: json['gst_percentage']?.toString(),
      paymentSchedule: json['payment_schedule'] is Map ? json['payment_schedule'] : null,
      additionalCharges: json['additional_charges'] is Map ? json['additional_charges'] : null,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floor': floor,
      'flat_type': flatType,
      'base_price': basePrice,
      if (pricePerSqft != null && pricePerSqft!.isNotEmpty) 'price_per_sqft': pricePerSqft,
      if (bookingAmount != null && bookingAmount!.isNotEmpty) 'booking_amount': bookingAmount,
      if (discountPercentage != null && discountPercentage!.isNotEmpty) 'discount_percentage': discountPercentage,
      if (gstPercentage != null && gstPercentage!.isNotEmpty) 'gst_percentage': gstPercentage,
      if (paymentSchedule != null && paymentSchedule!.isNotEmpty) 'payment_schedule': paymentSchedule,
      if (additionalCharges != null && additionalCharges!.isNotEmpty) 'additional_charges': additionalCharges,
      'is_available': isAvailable,
    };
  }
}

// ==================== SELLER ====================
class Seller {
  final String name;
  final String phone;
  final String? email;
  final String? company;
  final String? designation;
  final int? experienceYears;
  final String? whatsappNumber;
  final bool isPrimary;
  final bool isActive;

  Seller({
    required this.name,
    required this.phone,
    this.email,
    this.company,
    this.designation,
    this.experienceYears,
    this.whatsappNumber,
    this.isPrimary = false,
    this.isActive = true,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      company: json['company'],
      designation: json['designation'],
      experienceYears: json['experience_years'],
      whatsappNumber: json['whatsapp_number'],
      isPrimary: json['is_primary'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (company != null && company!.isNotEmpty) 'company': company,
      if (designation != null && designation!.isNotEmpty) 'designation': designation,
      if (experienceYears != null) 'experience_years': experienceYears,
      if (whatsappNumber != null && whatsappNumber!.isNotEmpty) 'whatsapp_number': whatsappNumber,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }
}

// ==================== FEATURE MODEL ====================
class PropertyFeature {
  final String key;
  final String value;

  PropertyFeature({required this.key, required this.value});

  Map<String, dynamic> toJson() => {key: value};
}

// ==================== REQUEST MODEL ====================
class PropertyCreateRequest {
  final String title;
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
  final String? googleLocationUrl;
  final String? totalArea;
  final String? plotArea;
  final int? totalFloors;
  final int? totalTowers;
  final int? builder;
  final int? agent;
  final List<int>? amenities;
  final String? reraNumber;
  final String? reraQrCode;
  final String? reraWebsite;
  final List<String>? reraAdditionalUrls;
  final String? propertyWebsiteUrl;
  final bool? isUnderConstruction;
  final String? possessionDate;
  final int? completionPercentage;
  final bool? isFeatured;
  final bool? isVerified;
  final bool? isNegotiable;
  final Map<String, dynamic>? features;
  final List<FlatType>? flatTypes;
  final List<Floor>? floors;
  final List<PricingSlab>? pricingSlabs;
  final List<Seller>? sellers;
  final List<MediaFile>? images;
  final List<MediaFile>? videos;
  final List<MediaFile>? documents;
  final String? source;
  final int? marketingPartner;

  PropertyCreateRequest({
    required this.title,
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
    this.googleLocationUrl,
    this.totalArea,
    this.plotArea,
    this.totalFloors,
    this.totalTowers,
    this.builder,
    this.agent,
    this.amenities,
    this.reraNumber,
    this.reraQrCode,
    this.reraWebsite,
    this.reraAdditionalUrls,
    this.propertyWebsiteUrl,
    this.isUnderConstruction,
    this.possessionDate,
    this.completionPercentage,
    this.isFeatured,
    this.isVerified,
    this.isNegotiable,
    this.features,
    this.flatTypes,
    this.floors,
    this.pricingSlabs,
    this.sellers,
    this.images,
    this.videos,
    this.documents,
    this.source,
    this.marketingPartner,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'property_type': propertyType,
      'transaction_type': transactionType,
      'status': status,
      'city': city,
      'area': area,
      'address': address,
    };


    if (landmark != null && landmark!.isNotEmpty) data['landmark'] = landmark;
    if (pincode != null && pincode!.isNotEmpty) data['pincode'] = pincode;
    if (latitude != null && latitude!.isNotEmpty) data['latitude'] = latitude;
    if (longitude != null && longitude!.isNotEmpty) data['longitude'] = longitude;
    if (googleLocationUrl != null && googleLocationUrl!.isNotEmpty) {
      data['google_location_url'] = googleLocationUrl;
    }
    if (totalArea != null && totalArea!.isNotEmpty) data['total_area'] = totalArea;
    if (plotArea != null && plotArea!.isNotEmpty) data['plot_area'] = plotArea;
    if (totalFloors != null) data['total_floors'] = totalFloors;
    if (totalTowers != null) data['total_towers'] = totalTowers;
    if (builder != null) data['builder'] = builder;
    if (agent != null) data['agent'] = agent;
    if (amenities != null && amenities!.isNotEmpty) data['amenities'] = amenities;
    if (reraNumber != null && reraNumber!.isNotEmpty) data['rera_number'] = reraNumber;
    if (reraQrCode != null && reraQrCode!.isNotEmpty) data['rera_qr_code'] = reraQrCode;
    if (reraWebsite != null && reraWebsite!.isNotEmpty) data['rera_website'] = reraWebsite;
    if (reraAdditionalUrls != null && reraAdditionalUrls!.isNotEmpty) {
      data['rera_additional_urls'] = reraAdditionalUrls;
    }
    if (propertyWebsiteUrl != null && propertyWebsiteUrl!.isNotEmpty) {
      data['property_website_url'] = propertyWebsiteUrl;
    }
    if (isUnderConstruction != null) data['is_under_construction'] = isUnderConstruction;
    if (possessionDate != null && possessionDate!.isNotEmpty) data['possession_date'] = possessionDate;
    if (completionPercentage != null) data['completion_percentage'] = completionPercentage;
    if (isFeatured != null) data['is_featured'] = isFeatured;
    if (isVerified != null) data['is_verified'] = isVerified;
    if (isNegotiable != null) data['is_negotiable'] = isNegotiable;
    if (features != null && features!.isNotEmpty) data['features'] = features;
    if (flatTypes != null && flatTypes!.isNotEmpty) {
      data['flat_types'] = flatTypes!.map((e) => e.toJson()).toList();
    }
    if (floors != null && floors!.isNotEmpty) {
      data['floors'] = floors!.map((e) => e.toJson()).toList();
    }
    if (pricingSlabs != null && pricingSlabs!.isNotEmpty) {
      data['pricing_slabs'] = pricingSlabs!.map((e) => e.toJson()).toList();
    }
    if (sellers != null && sellers!.isNotEmpty) {
      data['sellers'] = sellers!.map((e) => e.toJson()).toList();
    }
    // NOTE: images/videos/documents are NOT added to JSON.
    // They are handled separately via multipart in PropertyService.

    // ✅ ADD THIS BLOCK (near other optional fields)
    if (source != null && source!.isNotEmpty) {
      data['source'] = source;
    }
    if (marketingPartner != null && marketingPartner! > 0) {
      data['marketing_partner'] = marketingPartner;
    }


    return data;
  }
}

// ==================== RESPONSE MODEL ====================
class PropertyCreateResponse {
  final bool success;
  final String message;
  final int? propertyId;
  final PropertyData? data;
  final Map<String, List<String>>? errors;

  PropertyCreateResponse({
    required this.success,
    required this.message,
    this.propertyId,
    this.data,
    this.errors,
  });

  factory PropertyCreateResponse.fromJson(Map<String, dynamic> json) {
    PropertyData? parsedData;

    try {
      final rawData = json['data'];
      if (rawData != null && rawData is Map && rawData.isNotEmpty) {
        parsedData = PropertyData.fromJson(Map<String, dynamic>.from(rawData));
      }
    } catch (e) {
      print('⚠️ PropertyData parse failed: $e');
      parsedData = null;
    }

    return PropertyCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      propertyId: json['property_id'] ?? parsedData?.id,
      data: parsedData,
      errors: json['errors'] != null
          ? Map<String, List<String>>.from(
        (json['errors'] as Map).map(
              (k, v) => MapEntry(k.toString(), List<String>.from(v)),
        ),
      )
          : null,
    );
  }
}

// ==================== PROPERTY DATA (for create response) ====================
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
  final int? builder;
  final int? agent;
  final List<AmenityDetail>? amenityDetails;
  final String? reraNumber;
  final String? reraQrCode;
  final String? reraWebsite;
  final List<dynamic> reraAdditionalUrls;
  final String? propertyWebsiteUrl;
  final bool? isUnderConstruction;
  final String? possessionDate;
  final int? completionPercentage;
  final Map<String, dynamic>? features;
  final bool? isFeatured;
  final bool? isVerified;
  final bool? isNegotiable;
  final String? referralCode;
  final String createdAt;
  final String updatedAt;
  final String? publishedAt;
  final String? expiryDate;
  final List<dynamic> images;
  final List<dynamic> videos;
  final List<dynamic> documents;

  PropertyData({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.status,
    this.statusApproved = false,
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
    this.agent,
    this.amenityDetails,
    this.reraNumber,
    this.reraQrCode,
    this.reraWebsite,
    this.reraAdditionalUrls = const [],
    this.propertyWebsiteUrl,
    this.isUnderConstruction,
    this.possessionDate,
    this.completionPercentage,
    this.features,
    this.isFeatured,
    this.isVerified,
    this.isNegotiable,
    this.referralCode,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.expiryDate,
    this.images = const [],
    this.videos = const [],
    this.documents = const [],
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
      builder: json['builder'],
      agent: json['agent'],
      amenityDetails: json['amenity_details'] != null
          ? (json['amenity_details'] as List).map((e) => AmenityDetail.fromJson(e)).toList()
          : null,
      reraNumber: json['rera_number'],
      reraQrCode: json['rera_qr_code'],
      reraWebsite: json['rera_website'],
      reraAdditionalUrls: json['rera_additional_urls'] ?? [],
      propertyWebsiteUrl: json['property_website_url'],
      isUnderConstruction: json['is_under_construction'],
      possessionDate: json['possession_date'],
      completionPercentage: json['completion_percentage'],
      features: json['features'] is Map ? Map<String, dynamic>.from(json['features']) : null,
      isFeatured: json['is_featured'],
      isVerified: json['is_verified'],
      isNegotiable: json['is_negotiable'],
      referralCode: json['referral_code'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      publishedAt: json['published_at'],
      expiryDate: json['expiry_date'],
      images: json['images'] ?? [],
      videos: json['videos'] ?? [],
      documents: json['documents'] ?? [],
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