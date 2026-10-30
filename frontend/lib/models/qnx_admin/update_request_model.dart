// models/update_request_model.dart
import 'package:flutter/foundation.dart';

// ==================== SAFE CASTING HELPERS ====================
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<T> _toList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value == null) return [];
  if (value is! List) return [];
  return value
      .whereType<Map<String, dynamic>>()
      .map((e) => fromJson(e))
      .toList();
}

// ==================== RESPONSE MODELS ====================
class UpdateRequestListResponse {
  final bool status;
  final int count;
  final List<UpdateRequest> results;

  UpdateRequestListResponse({
    required this.status,
    required this.count,
    required this.results,
  });

  factory UpdateRequestListResponse.fromJson(Map<String, dynamic> json) {
    // FIX: The outer 'results' is a map, not a list.
    final inner = json['results'];
    if (inner is Map<String, dynamic>) {
      final resultsList = _toList(inner['results'], (e) => UpdateRequest.fromJson(e));
      return UpdateRequestListResponse(
        status: inner['status'] == true,
        count: _toInt(inner['count']),
        results: resultsList,
      );
    }
    // Fallback if API changes
    return UpdateRequestListResponse(
      status: json['status'] == true,
      count: _toInt(json['count']),
      results: _toList(json['results'], (e) => UpdateRequest.fromJson(e)),
    );
  }
}

class UpdateRequest {
  final int requestId;
  final String status;
  final String createdAt;
  final RequestedBy requestedBy;
  final ProductSummary product;
  final UpdatedData updatedData;

  UpdateRequest({
    required this.requestId,
    required this.status,
    required this.createdAt,
    required this.requestedBy,
    required this.product,
    required this.updatedData,
  });

  factory UpdateRequest.fromJson(Map<String, dynamic> json) {
    return UpdateRequest(
      requestId: _toInt(json['request_id']),
      status: _toString(json['status']),
      createdAt: _toString(json['created_at']),
      requestedBy: RequestedBy.fromJson(_toMap(json['requested_by'])),
      product: ProductSummary.fromJson(_toMap(json['product'])),
      updatedData: UpdatedData.fromJson(_toMap(json['updated_data'])),
    );
  }
}

class RequestedBy {
  final int id;
  final String name;
  final String email;

  RequestedBy({required this.id, required this.name, required this.email});

  factory RequestedBy.fromJson(Map<String, dynamic> json) {
    return RequestedBy(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      email: _toString(json['email']),
    );
  }
}

class ProductSummary {
  final int id;
  final String name;
  final double price;
  final String thumbnail;

  ProductSummary({
    required this.id,
    required this.name,
    required this.price,
    required this.thumbnail,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      price: _toDouble(json['price']),
      thumbnail: _toString(json['thumbnail']),
    );
  }
}

class UpdatedData {
  final List<dynamic> images;
  final List<dynamic> videos;
  final List<VariantUpdate> variants;
  final String? thumbnail;
  final Map<String, dynamic> productData;
  final List<dynamic> deleteImages;
  final List<dynamic> deleteVideos;

  UpdatedData({
    required this.images,
    required this.videos,
    required this.variants,
    this.thumbnail,
    required this.productData,
    required this.deleteImages,
    required this.deleteVideos,
  });

  factory UpdatedData.fromJson(Map<String, dynamic> json) {
    // Safely parse variants list
    final variantsData = json['variants'];
    List<VariantUpdate> variantList = [];
    if (variantsData is List) {
      for (var item in variantsData) {
        if (item is Map<String, dynamic>) {
          variantList.add(VariantUpdate.fromJson(item));
        }
      }
    }

    return UpdatedData(
      images: json['images'] is List ? json['images'] as List : [],
      videos: json['videos'] is List ? json['videos'] as List : [],
      variants: variantList,
      thumbnail: json['thumbnail'] as String?,
      productData: json['product_data'] is Map
          ? Map<String, dynamic>.from(json['product_data'])
          : {},
      deleteImages: json['delete_images'] is List ? json['delete_images'] as List : [],
      deleteVideos: json['delete_videos'] is List ? json['delete_videos'] as List : [],
    );
  }
}

class VariantUpdate {
  final int? id;
  final String sku;
  final int price;
  final int stockQuantity;
  final Map<String, dynamic> attributes;
  final int? imageIndex;

  VariantUpdate({
    this.id,
    required this.sku,
    required this.price,
    required this.stockQuantity,
    required this.attributes,
    this.imageIndex,
  });

  factory VariantUpdate.fromJson(Map<String, dynamic> json) {
    return VariantUpdate(
      id: json['id'] != null ? _toInt(json['id']) : null,
      sku: _toString(json['sku']),
      price: _toInt(json['price']),
      stockQuantity: _toInt(json['stock_quantity'] ?? json['stock'] ?? 0),
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'])
          : {},
      imageIndex: json['image_index'] != null ? _toInt(json['image_index']) : null,
    );
  }
}

// ========== Approve / Reject Models ==========
class ApproveUpdateResponse {
  final bool status;
  final String message;

  ApproveUpdateResponse({required this.status, required this.message});

  factory ApproveUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ApproveUpdateResponse(
      status: json['status'] == true,
      message: _toString(json['message']),
    );
  }
}

class RejectUpdateResponse {
  final bool status;
  final String message;
  final Map<String, dynamic>? data;

  RejectUpdateResponse({required this.status, required this.message, this.data});

  factory RejectUpdateResponse.fromJson(Map<String, dynamic> json) {
    return RejectUpdateResponse(
      status: json['status'] == true,
      message: _toString(json['message']),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
    );
  }
}