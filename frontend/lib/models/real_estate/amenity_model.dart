// lib/models/real_estate/amenity_model.dart
class Amenity {
  final int id;
  final String name;
  final bool isActive;
  final String createdAt;

  Amenity({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_active': isActive,
    };
  }
}

// Response Models
class AmenityListResponse {
  final bool status;
  final String message;
  final int count;
  final List<Amenity> data;

  AmenityListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory AmenityListResponse.fromJson(Map<String, dynamic> json) {
    return AmenityListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: json['data'] != null
          ? List<Amenity>.from(json['data'].map((x) => Amenity.fromJson(x)))
          : [],
    );
  }
}

class AmenityCreateResponse {
  final bool status;
  final String message;
  final Amenity data;

  AmenityCreateResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AmenityCreateResponse.fromJson(Map<String, dynamic> json) {
    return AmenityCreateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: Amenity.fromJson(json['data'] ?? {}),
    );
  }
}