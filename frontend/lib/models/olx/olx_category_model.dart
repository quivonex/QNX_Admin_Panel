// lib/models/qnx_admin/olx_category_model.dart

class OlxCategoryRequest {
  final String name;
  final String slug;
  final String? description;
  final bool isActive;
  final int? sortOrder;

  OlxCategoryRequest({
    required this.name,
    required this.slug,
    this.description,
    this.isActive = true,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description ?? '',
      'is_active': isActive,
      'sort_order': sortOrder ?? 0,
    };
  }
}

class OlxCategoryResponse {
  final bool success;
  final String message;
  final int? id;

  OlxCategoryResponse({
    required this.success,
    required this.message,
    this.id,
  });

  factory OlxCategoryResponse.fromJson(Map<String, dynamic> json) {
    return OlxCategoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      id: json['id'],
    );
  }
}

// For List Response
class OlxCategoryListResponse {
  final bool success;
  final List<OlxCategory> data;

  OlxCategoryListResponse({
    required this.success,
    required this.data,
  });

  factory OlxCategoryListResponse.fromJson(Map<String, dynamic> json) {
    return OlxCategoryListResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OlxCategory.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class OlxCategory {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;
  final int? sortOrder;
  final List<OlxSubcategory> subcategories;
  final List<OlxAttribute> attributes;

  OlxCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.isActive = true,
    this.sortOrder,
    this.subcategories = const [],
    this.attributes = const [],
  });

  factory OlxCategory.fromJson(Map<String, dynamic> json) {
    return OlxCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'],
      subcategories: (json['subcategories'] as List<dynamic>?)
          ?.map((e) => OlxSubcategory.fromJson(e))
          .toList() ??
          [],
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((e) => OlxAttribute.fromJson(e))
          .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OlxCategory &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class OlxSubcategory {
  final int id;
  final String name;
  final String slug;
  final List<OlxAttribute> attributes;

  OlxSubcategory({
    required this.id,
    required this.name,
    required this.slug,
    this.attributes = const [],
  });

  factory OlxSubcategory.fromJson(Map<String, dynamic> json) {
    return OlxSubcategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((e) => OlxAttribute.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class OlxAttribute {
  final int id;
  final String name;
  final String key;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final int sortOrder;

  OlxAttribute({
    required this.id,
    required this.name,
    required this.key,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.sortOrder = 0,
  });

  factory OlxAttribute.fromJson(Map<String, dynamic> json) {
    return OlxAttribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      isRequired: json['is_required'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}