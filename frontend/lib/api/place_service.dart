// lib/services/place_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_url.dart';
import '../models/map/place_model.dart';

class PlaceService {
  final http.Client _client;
  final Duration _timeout;

  PlaceService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;


  /// Search nearby places with pagination support

  /// Search nearby places with pagination support
  Future<NearbyPlacesResponse> searchNearbyPlaces({
    required double lat,
    required double lng,
    required int radius,
    String? keyword,
    String? pageToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final requestBody = NearbyPlacesRequest(
        lat: lat,
        lng: lng,
        radius: radius,
        keyword: keyword,
        pageToken: pageToken,
      );

      print('📤 Searching nearby places');
      print('📍 Location: $lat, $lng');
      print('📏 Radius: $radius meters');
      print('🔑 Keyword: $keyword');
      print('📄 Page Token: $pageToken');

      final response = await _client.post(
        Uri.parse(ApiUrls.nearbyPlacesApi),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return NearbyPlacesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Search Places Error: $e');
      rethrow;
    }
  }

  Future<String?> getLocationName({
    required double lat,
    required double lng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _client.get(
        Uri.parse('${ApiUrls.reverseGeocodeApi}?lat=$lat&lng=$lng'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['display_name'] ?? jsonData['name'] ?? 'Unknown Location';
      }
      return null;
    } catch (e) {
      print('❌ Reverse Geocoding Error: $e');
      return null;
    }
  }

  Future<String?> getLocationNameFromGoogle({
    required double lat,
    required double lng,
  }) async {
    try {
      // You'll need to add your Google Maps API key
      const String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";

      final response = await _client.get(
        Uri.parse('${ApiUrls.googleGeocodeUrl}?latlng=$lat,$lng&key=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'OK' && jsonData['results'].isNotEmpty) {
          return jsonData['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Google Geocode Error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

