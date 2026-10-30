// lib/models/real_estate/my_properties_model.dart

import 'dart:convert';

// ==================== REQUEST MODELS ====================

class MyPropertiesRequest {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? propertyType;
  final String? status;
  final String? transactionType;

  MyPropertiesRequest({
    this.page,
    this.pageSize,
    this.search,
    this.propertyType,
    this.status,
    this.transactionType,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (page != null) data['page'] = page;
    if (pageSize != null) data['page_size'] = pageSize;
    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (propertyType != null && propertyType!.isNotEmpty) {
      data['property_type'] = propertyType;
    }
    if (status != null && status!.isNotEmpty) data['status'] = status;
    if (transactionType != null && transactionType!.isNotEmpty) {
      data['transaction_type'] = transactionType;
    }
    return data;
  }
}

class PropertyUpdateRequest {
  final int propertyId;
  final String? title;
  final String? description;
  final String? propertyType;
  final String? transactionType;
  final String? city;
  final String? area;
  final String? address;
  final String? landmark;
  final String? pincode;
  final String? latitude;
  final String? longitude;
  final String? googleLocationUrl;
  final String? totalArea;
  final String? plotArea;
  final int? totalFloors;
  final int? totalTowers;
  final String? reraNumber;
  final String? reraQrCode;
  final String? reraWebsite;
  final List<String>? reraAdditionalUrls;
  final String? propertyWebsiteUrl;
  final bool? isUnderConstruction;
  final bool? readyToMove;
  final String? possessionDate;
  final int? completionPercentage;
  final Map<String, dynamic>? features;
  final bool? isFeatured;
  final bool? isVerified;
  final bool? isNegotiable;

  PropertyUpdateRequest({
    required this.propertyId,
    this.title,
    this.description,
    this.propertyType,
    this.transactionType,
    this.city,
    this.area,
    this.address,
    this.landmark,
    this.pincode,
    this.latitude,
    this.longitude,
    this.googleLocationUrl,
    this.totalArea,
    this.plotArea,
    this.totalFloors,
    this.totalTowers,
    this.reraNumber,
    this.reraQrCode,
    this.reraWebsite,
    this.reraAdditionalUrls,
    this.propertyWebsiteUrl,
    this.isUnderConstruction,
    this.readyToMove,
    this.possessionDate,
    this.completionPercentage,
    this.features,
    this.isFeatured,
    this.isVerified,
    this.isNegotiable,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'property_id': propertyId,
    };
    if (title != null && title!.isNotEmpty) data['title'] = title;
    if (description != null && description!.isNotEmpty) data['description'] = description;
    if (propertyType != null && propertyType!.isNotEmpty) data['property_type'] = propertyType;
    if (transactionType != null && transactionType!.isNotEmpty) data['transaction_type'] = transactionType;
    if (city != null && city!.isNotEmpty) data['city'] = city;
    if (area != null && area!.isNotEmpty) data['area'] = area;
    if (address != null && address!.isNotEmpty) data['address'] = address;
    if (landmark != null) data['landmark'] = landmark;
    if (pincode != null) data['pincode'] = pincode;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (googleLocationUrl != null) data['google_location_url'] = googleLocationUrl;
    if (totalArea != null) data['total_area'] = totalArea;
    if (plotArea != null) data['plot_area'] = plotArea;
    if (totalFloors != null) data['total_floors'] = totalFloors;
    if (totalTowers != null) data['total_towers'] = totalTowers;
    if (reraNumber != null) data['rera_number'] = reraNumber;
    if (reraQrCode != null) data['rera_qr_code'] = reraQrCode;
    if (reraWebsite != null) data['rera_website'] = reraWebsite;
    if (reraAdditionalUrls != null) data['rera_additional_urls'] = reraAdditionalUrls;
    if (propertyWebsiteUrl != null) data['property_website_url'] = propertyWebsiteUrl;
    if (isUnderConstruction != null) data['is_under_construction'] = isUnderConstruction;
    if (readyToMove != null) data['ready_to_move'] = readyToMove;
    if (possessionDate != null) data['possession_date'] = possessionDate;
    if (completionPercentage != null) data['completion_percentage'] = completionPercentage;
    if (features != null) data['features'] = features;
    if (isFeatured != null) data['is_featured'] = isFeatured;
    if (isVerified != null) data['is_verified'] = isVerified;
    if (isNegotiable != null) data['is_negotiable'] = isNegotiable;
    return data;
  }
}

// ==================== RESPONSE MODELS ====================

class MyPropertiesResponse {
  final bool status;
  final String message;
  final int count;
  final List<MyPropertyData> data;

  MyPropertiesResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MyPropertiesResponse.fromJson(Map<String, dynamic> json) {
    return MyPropertiesResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MyPropertyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'count': count,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class MyPropertyData {
  final int id;
  final List<AmenityDetail> amenityDetails;
  final List<PropertyImage> images;
  final List<PropertyVideo> videos;
  final List<PropertyDocument> documents;
  final String title;
  final String slug;
  final String description;
  final String propertyType;
  final String transactionType;
  final String? propertyCondition;
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
  final String? reraNumber;
  final String? reraQrCode;
  final String? reraWebsite;
  final List<String> reraAdditionalUrls;
  final String? propertyWebsiteUrl;
  final bool isUnderConstruction;
  final bool readyToMove;
  final String? possessionDate;
  final int? completionPercentage;
  final Map<String, dynamic> features;
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
  final String? publishedAt;
  final String? expiryDate;
  final int? builder;
  final int? agent;

  MyPropertyData({
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
    this.propertyCondition,
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
    this.reraNumber,
    this.reraQrCode,
    this.reraWebsite,
    required this.reraAdditionalUrls,
    this.propertyWebsiteUrl,
    required this.isUnderConstruction,
    required this.readyToMove,
    this.possessionDate,
    this.completionPercentage,
    required this.features,
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
    this.publishedAt,
    this.expiryDate,
    this.builder,
    this.agent,
  });

  factory MyPropertyData.fromJson(Map<String, dynamic> json) {
    return MyPropertyData(





      id: json['id'] ?? 0,
      amenityDetails: (json['amenity_details'] as List<dynamic>?)
          ?.map((e) => AmenityDetail.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => PropertyImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => PropertyVideo.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => PropertyDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      propertyType: json['property_type'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      propertyCondition: json['property_condition'],
      status: json['status'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'],
      pincode: json['pincode'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      googleLocationUrl: json['google_location_url'],
      totalArea: json['total_area'],
      plotArea: json['plot_area'],
      totalFloors: json['total_floors'],
      totalTowers: json['total_towers'],
      reraNumber: json['rera_number'],
      reraQrCode: json['rera_qr_code'],
      reraWebsite: json['rera_website'],
      reraAdditionalUrls: (json['rera_additional_urls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      propertyWebsiteUrl: json['property_website_url'],
      isUnderConstruction: json['is_under_construction'] ?? false,
      readyToMove: json['ready_to_move'] ?? false,
      possessionDate: json['possession_date'],
      completionPercentage: json['completion_percentage'],
      features: _parseFeatures(json['features']),
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
      publishedAt: json['published_at'],
      expiryDate: json['expiry_date'],
      builder: json['builder'],
      agent: json['agent'],
    );
  }

  // ✅ NEW: Safe parser for features (handles String, Map, null)
  static Map<String, dynamic> _parseFeatures(dynamic value) {
    if (value == null) return {};

    // Already a proper Map
    if (value is Map<String, dynamic>) return value;

    // It's a Map but with dynamic values
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }

    // It's a JSON string → decode it
    if (value is String) {
      if (value.trim().isEmpty) return {};
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (e) {
        print('❌ Failed to parse features string: $e');
      }
    }

    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amenity_details': amenityDetails.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
      'videos': videos.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'title': title,
      'slug': slug,
      'description': description,
      'property_type': propertyType,
      'transaction_type': transactionType,
      'property_condition': propertyCondition,
      'status': status,
      'city': city,
      'area': area,
      'address': address,
      'landmark': landmark,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'google_location_url': googleLocationUrl,
      'total_area': totalArea,
      'plot_area': plotArea,
      'total_floors': totalFloors,
      'total_towers': totalTowers,
      'rera_number': reraNumber,
      'rera_qr_code': reraQrCode,
      'rera_website': reraWebsite,
      'rera_additional_urls': reraAdditionalUrls,
      'property_website_url': propertyWebsiteUrl,
      'is_under_construction': isUnderConstruction,
      'ready_to_move': readyToMove,
      'possession_date': possessionDate,
      'completion_percentage': completionPercentage,
      'features': features,
      'views_count': viewsCount,
      'enquiry_count': enquiryCount,
      'favorite_count': favoriteCount,
      'status_approved': statusApproved,
      'is_featured': isFeatured,
      'is_verified': isVerified,
      'is_negotiable': isNegotiable,
      'referral_code': referralCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'published_at': publishedAt,
      'expiry_date': expiryDate,
      'builder': builder,
      'agent': agent,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

class PropertyImage {
  final int id;
  final String imageS3Key;
  final String? caption;
  final bool isPrimary;

  PropertyImage({
    required this.id,
    required this.imageS3Key,
    this.caption,
    required this.isPrimary,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'] ?? 0,
      imageS3Key: json['image_s3_key'] ?? '',
      caption: json['caption'],
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_s3_key': imageS3Key,
      'caption': caption,
      'is_primary': isPrimary,
    };
  }
}

class PropertyVideo {
  final int id;
  final String videoS3Key;
  final String? title;
  final bool isFeatured;

  PropertyVideo({
    required this.id,
    required this.videoS3Key,
    this.title,
    required this.isFeatured,
  });

  factory PropertyVideo.fromJson(Map<String, dynamic> json) {
    return PropertyVideo(
      id: json['id'] ?? 0,
      videoS3Key: json['video_s3_key'] ?? '',
      title: json['title'],
      isFeatured: json['is_featured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_s3_key': videoS3Key,
      'title': title,
      'is_featured': isFeatured,
    };
  }
}

class PropertyDocument {
  final int id;
  final String documentType;
  final String title;
  final String? description;

  PropertyDocument({
    required this.id,
    required this.documentType,
    required this.title,
    this.description,
  });

  factory PropertyDocument.fromJson(Map<String, dynamic> json) {
    return PropertyDocument(
      id: json['id'] ?? 0,
      documentType: json['document_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'title': title,
      'description': description,
    };
  }
}

class PropertyUpdateResponse {
  final bool success;
  final String message;
  final int? propertyId;
  final MyPropertyData? data;

  PropertyUpdateResponse({
    required this.success,
    required this.message,
    this.propertyId,
    this.data,
  });

  factory PropertyUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PropertyUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      propertyId: json['property_id'],
      data: json['data'] != null
          ? MyPropertyData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'property_id': propertyId,
      'data': data?.toJson(),
    };
  }
}