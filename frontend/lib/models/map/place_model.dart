// lib/models/place_model.dart
import 'package:json_annotation/json_annotation.dart';

class PlaceLatLng {
  final double lat;
  final double lng;

  PlaceLatLng({
    required this.lat,
    required this.lng,
  });

  factory PlaceLatLng.fromJson(Map<String, dynamic> json) {
    return PlaceLatLng(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class NearbyPlacesResponse {
  final String status;
  final List<PlaceResult> results;
  final String? nextPageToken;
  final List<dynamic> htmlAttributions;

  NearbyPlacesResponse({
    required this.status,
    required this.results,
    this.nextPageToken,
    this.htmlAttributions = const [],
  });

  factory NearbyPlacesResponse.fromJson(Map<String, dynamic> json) {
    return NearbyPlacesResponse(
      status: json['status']?.toString() ?? '',
      results: (json['results'] as List? ?? [])
          .map((e) => PlaceResult.fromJson(e))
          .toList(),
      nextPageToken: json['next_page_token']?.toString(),
      htmlAttributions: json['html_attributions'] ?? [],
    );
  }
}

class PlaceResult {
  final String placeId;
  final String name;
  final String? vicinity;
  final String? formattedAddress;
  final LocationGeometry geometry;
  final String? icon;
  final String? iconBackgroundColor;
  final String? iconMaskBaseUri;
  final String? internationalPhoneNumber;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final String? businessStatus;
  final OpeningHours? openingHours;
  final List<Photo>? photos;
  final String? reference;

  PlaceResult({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.formattedAddress,
    required this.geometry,
    this.icon,
    this.iconBackgroundColor,
    this.iconMaskBaseUri,
    this.internationalPhoneNumber,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.businessStatus,
    this.openingHours,
    this.photos,
    this.reference,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    List<String> parseTypes(dynamic typesData) {
      if (typesData == null) return [];
      if (typesData is List) {
        return typesData.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return PlaceResult(
      placeId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Place',
      vicinity: json['vicinity']?.toString(),
      formattedAddress: json['formatted_address']?.toString(),
      geometry: LocationGeometry.fromJson(json['geometry'] ?? {}),
      icon: json['icon']?.toString(),
      iconBackgroundColor: json['icon_background_color']?.toString(),
      iconMaskBaseUri: json['icon_mask_base_uri']?.toString(),
      internationalPhoneNumber: json['international_phone_number']?.toString(),
      rating: _parseDouble(json['rating']),
      userRatingsTotal: _parseInt(json['user_ratings_total']),
      types: parseTypes(json['types']),
      businessStatus: json['business_status']?.toString(),
      openingHours: json['opening_hours'] != null
          ? OpeningHours.fromJson(json['opening_hours'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((e) => Photo.fromJson(e)).toList()
          : null,
      reference: json['reference']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get displayAddress => formattedAddress ?? vicinity ?? 'No address available';
  String get displayPhone => internationalPhoneNumber ?? 'Not available';
  String get displayRating => rating != null ? '⭐ ${rating!.toStringAsFixed(1)}' : 'No rating';
  String get displayStatus => businessStatus ?? 'Unknown';
  bool get isOperational => businessStatus == 'OPERATIONAL';
  bool get isOpenNow => openingHours?.openNow ?? false;
}

class LocationGeometry {
  final PlaceLatLng location;
  final Viewport viewport;

  LocationGeometry({
    required this.location,
    required this.viewport,
  });

  factory LocationGeometry.fromJson(Map<String, dynamic> json) {
    return LocationGeometry(
      location: PlaceLatLng.fromJson(json['location'] ?? {}),
      viewport: Viewport.fromJson(json['viewport'] ?? {}),
    );
  }
}

class Viewport {
  final PlaceLatLng northeast;
  final PlaceLatLng southwest;

  Viewport({
    required this.northeast,
    required this.southwest,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      northeast: PlaceLatLng.fromJson(json['northeast'] ?? {}),
      southwest: PlaceLatLng.fromJson(json['southwest'] ?? {}),
    );
  }
}

class OpeningHours {
  final bool openNow;

  OpeningHours({
    required this.openNow,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] ?? false,
    );
  }
}

class Photo {
  final int height;
  final int width;
  final String photoReference;
  final List<String> htmlAttributions;

  Photo({
    required this.height,
    required this.width,
    required this.photoReference,
    this.htmlAttributions = const [],
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      height: json['height'] ?? 0,
      width: json['width'] ?? 0,
      photoReference: json['photo_reference']?.toString() ?? '',
      htmlAttributions: (json['html_attributions'] as List? ?? [])
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

// Request Model
class NearbyPlacesRequest {
  final double lat;
  final double lng;
  final int radius;
  final String? keyword;
  final String? pageToken;

  NearbyPlacesRequest({
    required this.lat,
    required this.lng,
    required this.radius,
    this.keyword,
    this.pageToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
      if (pageToken != null && pageToken!.isNotEmpty) 'page_token': pageToken,
    };
  }
}