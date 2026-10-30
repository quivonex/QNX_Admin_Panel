// lib/models/real_estate/pdf_extract_model.dart

class PdfExtractResponse {
  final bool success;
  final String? documentId;
  final PdfPropertyData? data;
  final List<PdfImage> images;

  PdfExtractResponse({
    required this.success,
    this.documentId,
    this.data,
    this.images = const [],
  });

  factory PdfExtractResponse.fromJson(Map<String, dynamic> json) {
    return PdfExtractResponse(
      success: json['success'] ?? false,
      documentId: json['document_id'],
      data: json['data'] != null
          ? PdfPropertyData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
      images: (json['images'] as List?)
          ?.map((e) => PdfImage.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          [],
    );
  }
}

// ==================== PROPERTY DATA ====================
class PdfPropertyData {
  final String title;
  final String description;
  final String propertyType;
  final String transactionType;
  final String status;
  final String city;
  final String area;
  final String address;
  final String landmark;
  final String pincode;
  final num? latitude;
  final num? longitude;
  final String googleLocationUrl;
  final num? totalArea;
  final String totalAreaUnit;
  final num? plotArea;
  final String plotAreaUnit;
  final int? totalFloors;
  final int? totalTowers;
  final PdfBuilder? builder;
  final PdfAgent? agent;
  final String reraNumber;
  final String reraQrCode;
  final String reraWebsite;
  final List<String> reraAdditionalUrls;
  final String propertyWebsiteUrl;
  final bool isUnderConstruction;
  final String possessionDate;
  final int? completionPercentage;
  final bool isFeatured;
  final bool isVerified;
  final bool isNegotiable;
  final List<String> amenities;
  final List<PdfFeature> features;
  final List<PdfFlatType> flatTypes;
  final List<dynamic> floors;
  final List<dynamic> pricingSlabs;

  PdfPropertyData({
    required this.title,
    required this.description,
    required this.propertyType,
    required this.transactionType,
    required this.status,
    required this.city,
    required this.area,
    required this.address,
    required this.landmark,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.googleLocationUrl,
    this.totalArea,
    required this.totalAreaUnit,
    this.plotArea,
    required this.plotAreaUnit,
    this.totalFloors,
    this.totalTowers,
    this.builder,
    this.agent,
    required this.reraNumber,
    required this.reraQrCode,
    required this.reraWebsite,
    required this.reraAdditionalUrls,
    required this.propertyWebsiteUrl,
    required this.isUnderConstruction,
    required this.possessionDate,
    this.completionPercentage,
    required this.isFeatured,
    required this.isVerified,
    required this.isNegotiable,
    required this.amenities,
    required this.features,
    required this.flatTypes,
    required this.floors,
    required this.pricingSlabs,
  });

  factory PdfPropertyData.fromJson(Map<String, dynamic> json) {
    return PdfPropertyData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? 'flat',
      transactionType: json['transaction_type'] ?? 'sale',
      status: json['status'] ?? 'draft',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      googleLocationUrl: json['google_location_url'] ?? '',
      totalArea: json['total_area'],
      totalAreaUnit: json['total_area_unit'] ?? '',
      plotArea: json['plot_area'],
      plotAreaUnit: json['plot_area_unit'] ?? '',
      totalFloors: json['total_floors'],
      totalTowers: json['total_towers'],
      builder: json['builder'] != null && (json['builder'] as Map).isNotEmpty
          ? PdfBuilder.fromJson(Map<String, dynamic>.from(json['builder']))
          : null,
      agent: json['agent'] != null && (json['agent'] as Map).isNotEmpty
          ? PdfAgent.fromJson(Map<String, dynamic>.from(json['agent']))
          : null,
      reraNumber: json['rera_number'] ?? '',
      reraQrCode: json['rera_qr_code'] ?? '',
      reraWebsite: json['rera_website'] ?? '',
      reraAdditionalUrls: (json['rera_additional_urls'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      propertyWebsiteUrl: json['property_website_url'] ?? '',
      isUnderConstruction: json['is_under_construction'] ?? false,
      possessionDate: json['possession_date'] ?? '',
      completionPercentage: json['completion_percentage'],
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isNegotiable: json['is_negotiable'] ?? false,
      amenities: (json['amenities'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      features: (json['features'] as List?)
          ?.map((e) => PdfFeature.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          [],
      flatTypes: (json['flat_types'] as List?)
          ?.map((e) => PdfFlatType.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          [],
      floors: json['floors'] ?? [],
      pricingSlabs: json['pricing_slabs'] ?? [],
    );
  }
}

class PdfBuilder {
  final String name;
  final String shortInfo;
  final String website;
  final String email;
  final String phone;

  PdfBuilder({
    required this.name,
    required this.shortInfo,
    required this.website,
    required this.email,
    required this.phone,
  });

  factory PdfBuilder.fromJson(Map<String, dynamic> json) {
    return PdfBuilder(
      name: json['name'] ?? '',
      shortInfo: json['short_info'] ?? '',
      website: json['website'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PdfAgent {
  final String name;
  final String email;
  final String phone;

  PdfAgent({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory PdfAgent.fromJson(Map<String, dynamic> json) {
    return PdfAgent(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PdfFeature {
  final String name;
  final String value;

  PdfFeature({required this.name, required this.value});

  factory PdfFeature.fromJson(Map<String, dynamic> json) {
    return PdfFeature(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class PdfFlatType {
  final String flatType;
  final String? areaSqft;
  final int? bedrooms;
  final int? bathrooms;

  PdfFlatType({
    required this.flatType,
    this.areaSqft,
    this.bedrooms,
    this.bathrooms,
  });

  factory PdfFlatType.fromJson(Map<String, dynamic> json) {
    return PdfFlatType(
      flatType: json['flat_type'] ?? '',
      areaSqft: json['area_sqft']?.toString(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
    );
  }
}

class PdfImage {
  final int pageNumber;
  final int imageIndex;
  final String s3Key;
  final String url;

  PdfImage({
    required this.pageNumber,
    required this.imageIndex,
    required this.s3Key,
    required this.url,
  });

  factory PdfImage.fromJson(Map<String, dynamic> json) {
    return PdfImage(
      pageNumber: json['page_number'] ?? 0,
      imageIndex: json['image_index'] ?? 0,
      s3Key: json['s3_key'] ?? '',
      url: json['url'] ?? '',
    );
  }
}