// lib/models/real_estate/builder_model.dart

import 'dart:convert';
import 'dart:typed_data';
class BuilderModel {
  final int? id;
  final String name;
  final String shortInfo;
  final String? logo;
  final String? website;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  BuilderModel({
    this.id,
    required this.name,
    required this.shortInfo,
    this.logo,
    this.website,
    this.email,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BuilderModel.fromJson(Map<String, dynamic> json) {
    return BuilderModel(
      id: json['id'],
      name: json['name'] ?? '',
      shortInfo: json['short_info'] ?? '',
      logo: json['logo'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'short_info': shortInfo,
      if (logo != null) 'logo': logo,
      if (website != null) 'website': website,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'is_active': isActive,
    };
  }
}

// Response Model
class BuilderCreateResponse {
  final bool success;
  final String message;
  final int? builderId;
  final BuilderModel? data;

  BuilderCreateResponse({
    required this.success,
    required this.message,
    this.builderId,
    this.data,
  });

  factory BuilderCreateResponse.fromJson(Map<String, dynamic> json) {
    return BuilderCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      builderId: json['builder_id'],
      data: json['data'] != null ? BuilderModel.fromJson(json['data']) : null,
    );
  }
}