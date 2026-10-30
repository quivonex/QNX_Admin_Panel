// lib/models/shiprocket/packing_video_model.dart

class PackingVideoRequest {
  final int orderId;

  PackingVideoRequest({
    required this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
    };
  }
}

class PackingVideoResponse {
  final bool success;
  final String message;
  final PackingVideoData? data;

  PackingVideoResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PackingVideoResponse.fromJson(Map<String, dynamic> json) {
    return PackingVideoResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PackingVideoData.fromJson(json['data']) : null,
    );
  }
}

class PackingVideoData {
  final int id;
  final int order;
  final int uploadedBy;
  final String s3Video;

  PackingVideoData({
    required this.id,
    required this.order,
    required this.uploadedBy,
    required this.s3Video,
  });

  factory PackingVideoData.fromJson(Map<String, dynamic> json) {
    return PackingVideoData(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      uploadedBy: json['uploaded_by'] ?? 0,
      s3Video: json['s3_video'] ?? '',
    );
  }
}