// lib/models/olx/olx_attribute_model.dart

// ==================== ATTRIBUTE CREATE REQUEST ====================
class OlxAttributeRequest {
  final int categoryId;
  final int subcategoryId;
  final String name;
  final String key;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final bool isActive;
  final int? sortOrder;

  OlxAttributeRequest({
    required this.categoryId,
    required this.subcategoryId,
    required this.name,
    required this.key,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isActive = true,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'name': name,
      'key': key,
      'field_type': fieldType,
      'options': options,
      'is_required': isRequired,
      'is_active': isActive,
      'sort_order': sortOrder ?? 0,
    };
  }
}

// ==================== CREATE RESPONSE ====================
class OlxAttributeCreateResponse {
  final bool success;
  final String message;
  final OlxAttributeData? data;

  OlxAttributeCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OlxAttributeCreateResponse.fromJson(Map<String, dynamic> json) {
    return OlxAttributeCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OlxAttributeData.fromJson(json['data'])
          : null,
    );
  }
}

// ==================== ATTRIBUTE DATA ====================
class OlxAttributeData {
  final int id;
  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;
  final String name;
  final String key;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final bool isActive;
  final int? sortOrder;

  OlxAttributeData({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    required this.name,
    required this.key,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isActive = true,
    this.sortOrder,
  });

  factory OlxAttributeData.fromJson(Map<String, dynamic> json) {
    return OlxAttributeData(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      subcategoryId: json['subcategory_id'],
      subcategoryName: json['subcategory_name'],
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isRequired: json['is_required'] ?? false,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OlxAttributeData &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== LIST RESPONSE ====================
class OlxAttributeListResponse {
  final bool success;
  final String message;
  final OlxCategoryInfo? category;
  final OlxSubcategoryInfo? subcategory;
  final int count;
  final List<OlxAttributeData> data;

  OlxAttributeListResponse({
    required this.success,
    required this.message,
    this.category,
    this.subcategory,
    this.count = 0,
    this.data = const [],
  });

  factory OlxAttributeListResponse.fromJson(Map<String, dynamic> json) {
    return OlxAttributeListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      category: json['category'] != null
          ? OlxCategoryInfo.fromJson(json['category'])
          : null,
      subcategory: json['subcategory'] != null
          ? OlxSubcategoryInfo.fromJson(json['subcategory'])
          : null,
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OlxAttributeData.fromJson(e))
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

// ==================== SUBCATEGORY INFO ====================
class OlxSubcategoryInfo {
  final int id;
  final String name;
  final String slug;

  OlxSubcategoryInfo({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory OlxSubcategoryInfo.fromJson(Map<String, dynamic> json) {
    return OlxSubcategoryInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}