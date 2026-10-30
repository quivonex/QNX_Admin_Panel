// lib/models/olx/olx_subcategory_model.dart

// ==================== SUB-CATEGORY REQUEST ====================
class OlxSubcategoryRequest {
  final int category;
  final String name;
  final String slug;
  final bool isActive;
  final int? sortOrder;

  OlxSubcategoryRequest({
    required this.category,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'slug': slug,
      'is_active': isActive,
      'sort_order': sortOrder ?? 0,
    };
  }
}

// ==================== CREATE RESPONSE ====================
class OlxSubcategoryCreateResponse {
  final bool success;
  final String message;
  final OlxSubcategoryData? data;

  OlxSubcategoryCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxSubcategoryCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxSubcategoryCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxSubcategoryData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== SUB-CATEGORY DATA ====================
class OlxSubcategoryData {
  final int id;
  final int category;
  final String? categoryName;
  final String name;
  final String slug;
  final bool isActive;
  final int? sortOrder;
  final String? createdAt;

  OlxSubcategoryData({
    required this.id,
    required this.category,
    this.categoryName,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.sortOrder,
    this.createdAt,
  });

  factory OlxSubcategoryData.fromJson(Map<String, dynamic> json) {
    return OlxSubcategoryData(
      id: json['id'] ?? 0,
      category: json['category'] ?? 0,
      categoryName: json['category_name'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'],
      createdAt: json['created_at'],
    );
  }
}

// ==================== LIST RESPONSE ====================
class OlxSubcategoryListResponse {
  final bool success;
  final String message;
  final OlxCategoryInfo? category;
  final int count;
  final List<OlxSubcategoryData> data;

  OlxSubcategoryListResponse({
    required this.success,
    required this.message,
    this.category,
    this.count = 0,
    this.data = const [],
  });

  factory OlxSubcategoryListResponse.fromJson(Map<String, dynamic> json) {
    return OlxSubcategoryListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      category: json['category'] != null
          ? OlxCategoryInfo.fromJson(json['category'])
          : null,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OlxSubcategoryData.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// ==================== CATEGORY INFO ====================
class OlxCategoryInfo {
  final int id;
  final String name;
  final String slug;

  OlxCategoryInfo({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory OlxCategoryInfo.fromJson(Map<String, dynamic> json) {
    return OlxCategoryInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

// ==================== LIST REQUEST ====================
class OlxSubcategoryListRequest {
  final int categoryId;

  OlxSubcategoryListRequest({required this.categoryId});

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
    };
  }
}