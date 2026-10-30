// lib/models/real_estate/builder_list_model.dart

class BuilderListResponse {
  final bool success;
  final String message;
  final int count;
  final List<BuilderData> data;

  BuilderListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory BuilderListResponse.fromJson(Map<String, dynamic> json) {
    return BuilderListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? (json['data'] as List).map((e) => BuilderData.fromJson(e)).toList()
          : [],
    );
  }
}

// lib/models/real_estate/builder_list_model.dart

class BuilderData {
  final int id;
  final String name;
  final String shortInfo;
  final String? logo;      // <-- यात logo_s3_key ची value येईल
  final String? website;
  final String? email;
  final String? phone;
  final String? latitude;
  final String? longitude;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  BuilderData({
    required this.id,
    required this.name,
    required this.shortInfo,
    this.logo,
    this.website,
    this.email,
    this.phone,
    this.latitude,
    this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuilderData.fromJson(Map<String, dynamic> json) {
    return BuilderData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      shortInfo: json['short_info'] ?? '',
      // 👇 हा MAIN FIX आहे — logo_s3_key read करा
      logo: json['logo_s3_key'] ?? json['logo'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}