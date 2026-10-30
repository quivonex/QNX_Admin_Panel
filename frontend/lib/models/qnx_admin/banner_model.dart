// lib/models/banner_model.dart
class BannerImage {
  final int? id;
  final String? imageUrl;
  final String? title;
  final String? createdAt;

  BannerImage({
    this.id,
    this.imageUrl,
    this.title,
    this.createdAt,
  });

  factory BannerImage.fromJson(Map<String, dynamic> json) {
    return BannerImage(
      id: json['id'],
      imageUrl: json['image_url'],
      title: json['title'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    };
  }
}

// Upload Response
class UploadImageResponse {
  final String status;
  final String imageUrl;
  final int id;

  UploadImageResponse({
    required this.status,
    required this.imageUrl,
    required this.id,
  });

  factory UploadImageResponse.fromJson(Map<String, dynamic> json) {
    return UploadImageResponse(
      status: json['status'],
      imageUrl: json['image_url'],
      id: json['id'],
    );
  }
}

// Update Response
class UpdateImageResponse {
  final String status;
  final String message;
  final BannerImage data;

  UpdateImageResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UpdateImageResponse.fromJson(Map<String, dynamic> json) {
    return UpdateImageResponse(
      status: json['status'],
      message: json['message'],
      data: BannerImage.fromJson(json['data']),
    );
  }
}

// Delete Response
class DeleteImageResponse {
  final String status;
  final String message;

  DeleteImageResponse({
    required this.status,
    required this.message,
  });

  factory DeleteImageResponse.fromJson(Map<String, dynamic> json) {
    return DeleteImageResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}

// ✅ NEW: List Response
class BannerListResponse {
  final String status;
  final int count;
  final List<BannerImage> data;

  BannerListResponse({
    required this.status,
    required this.count,
    required this.data,
  });

  factory BannerListResponse.fromJson(Map<String, dynamic> json) {
    return BannerListResponse(
      status: json['status'],
      count: json['count'],
      data: List<BannerImage>.from(json['data'].map((x) => BannerImage.fromJson(x))),
    );
  }
}