// lib/api/realestate_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/real_estate/amenity_model.dart';
import '../models/real_estate/channel_partner_model.dart';
import '../models/real_estate/schedule_meeting_model.dart';
import 'api_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/real_estate/property_list_model.dart';
import '../models/real_estate/builder_model.dart';
import '../models/real_estate/property_model.dart';
import '../models/real_estate/builder_list_model.dart';
import '../models/real_estate/property_enquiry_model.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../models/channel_partner/channel_partner_enquiry_model.dart';
import '../models/real_estate/pdf_extract_model.dart';
import '../models/real_estate/marketing_partner_model.dart';
import 'dart:io';
import '../models/real_estate/my_properties_model.dart';
import '../models/real_estate/property_subscription_model.dart';


class RealEstateService {
  Future<AmenityListResponse> getAmenities() async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.amenityList),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return AmenityListResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load amenities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<AmenityCreateResponse> createAmenity(Amenity amenity) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.amenityCreate),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(amenity.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AmenityCreateResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create amenity');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}




class BuilderService {
  final http.Client _client;

  BuilderService({http.Client? client}) : _client = client ?? http.Client();

  /// Create a new builder (supports logo image upload)
  Future<BuilderCreateResponse> createBuilder({
    required String name,
    required String shortInfo,
    Uint8List? logoBytes,          // <-- NEW
    String? logoFileName,          // <-- NEW (e.g. "logo.png")
    String? website,
    String? email,
    String? phone,
    bool isActive = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // Build multipart request
      final uri = Uri.parse(ApiUrls.builderCreate);
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // NOTE: Do NOT set Content-Type manually; MultipartRequest sets it.

      // Text fields
      request.fields['name'] = name;
      request.fields['short_info'] = shortInfo;
      request.fields['is_active'] = isActive ? '1' : '0';

      if (website != null && website.isNotEmpty) {
        request.fields['website'] = website;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }

      // Logo file
      if (logoBytes != null && logoBytes.isNotEmpty) {
        final fileName = logoFileName ?? 'logo.png';
        final ext = fileName.split('.').last.toLowerCase();

        MediaType? mediaType;
        if (ext == 'jpg' || ext == 'jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else if (ext == 'png') {
          mediaType = MediaType('image', 'png');
        } else if (ext == 'webp') {
          mediaType = MediaType('image', 'webp');
        } else {
          mediaType = MediaType('image', 'png');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',                 // <-- field name your backend expects
            logoBytes,
            filename: fileName,
            contentType: mediaType,
          ),
        );
      }

      print('📤 Create Builder (multipart)');
      print('URL: $uri');
      print('Fields: ${request.fields}');
      print('Has logo: ${logoBytes != null && logoBytes.isNotEmpty}');

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return BuilderCreateResponse.fromJson(jsonData);
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to create builder');
      }
    } catch (e) {
      print('❌ Create Builder Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}



// lib/api/property_service.dart


// lib/api/realestate_service.dart

class PropertyService {
  final http.Client _client;

  PropertyService({http.Client? client}) : _client = client ?? http.Client();

  /// Create a new property — supports images, videos, documents
  Future<PropertyCreateResponse> createProperty(PropertyCreateRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final hasMedia = (request.images?.isNotEmpty ?? false) ||
          (request.videos?.isNotEmpty ?? false) ||
          (request.documents?.isNotEmpty ?? false);

      // If no media → send as JSON (faster)
      if (!hasMedia) {
        return _createPropertyJson(request, token);
      }

      // Otherwise → send as multipart
      return _createPropertyMultipart(request, token);
    } catch (e) {
      print('❌ Create Property Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  // ==================== JSON ONLY ====================
  Future<PropertyCreateResponse> _createPropertyJson(
      PropertyCreateRequest request, String token) async {
    final requestBody = request.toJson();

    print('📤 Create Property (JSON)');
    print('URL: ${ApiUrls.propertyCreate}');
    print('📤 Request Body: ${jsonEncode(requestBody)}');

    final response = await _client.post(
      Uri.parse(ApiUrls.propertyCreate),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 60));

    print('📥 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PropertyCreateResponse.fromJson(jsonDecode(response.body));
    } else {
      final jsonData = jsonDecode(response.body);
      throw Exception(jsonData['message'] ?? 'Failed to create property');
    }
  }

  // ==================== MULTIPART (with media) ====================
  Future<PropertyCreateResponse> _createPropertyMultipart(
      PropertyCreateRequest request, String token) async {
    final uri = Uri.parse(ApiUrls.propertyCreate);
    final multipart = http.MultipartRequest('POST', uri);

    multipart.headers['Authorization'] = 'Bearer $token';
    multipart.headers['Accept'] = 'application/json';

    // Convert request JSON → form fields
    final data = request.toJson();
    data.forEach((key, value) {
      if (value == null) return;
      if (value is List || value is Map) {
        multipart.fields[key] = jsonEncode(value);
      } else {
        multipart.fields[key] = value.toString();
      }
    });

    // Add images
    if (request.images != null) {
      for (var img in request.images!) {
        multipart.files.add(_toMultipartFile(img, 'images'));
      }
    }

    // Add videos
    if (request.videos != null) {
      for (var vid in request.videos!) {
        multipart.files.add(_toMultipartFile(vid, 'videos'));
      }
    }

    // Add documents
    if (request.documents != null) {
      for (var doc in request.documents!) {
        multipart.files.add(_toMultipartFile(doc, 'documents'));
      }
    }

    print('📤 Create Property (Multipart)');
    print('URL: $uri');
    print('Fields: ${multipart.fields.keys.toList()}');
    print('Files: ${multipart.files.map((f) => "${f.field}: ${f.filename}").toList()}');

    final streamed = await _client
        .send(multipart)
        .timeout(const Duration(seconds: 120));

    final response = await http.Response.fromStream(streamed);

    print('📥 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PropertyCreateResponse.fromJson(jsonDecode(response.body));
    } else {
      final jsonData = jsonDecode(response.body);
      throw Exception(jsonData['message'] ?? 'Failed to create property');
    }
  }

  http.MultipartFile _toMultipartFile(MediaFile file, String fieldName) {
    final ext = file.name.split('.').last.toLowerCase();

    MediaType? mediaType;
    if (ext == 'jpg' || ext == 'jpeg') {
      mediaType = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      mediaType = MediaType('image', 'png');
    } else if (ext == 'webp') {
      mediaType = MediaType('image', 'webp');
    } else if (ext == 'gif') {
      mediaType = MediaType('image', 'gif');
    } else if (ext == 'mp4') {
      mediaType = MediaType('video', 'mp4');
    } else if (ext == 'mov') {
      mediaType = MediaType('video', 'quicktime');
    } else if (ext == 'pdf') {
      mediaType = MediaType('application', 'pdf');
    } else if (ext == 'doc') {
      mediaType = MediaType('application', 'msword');
    } else if (ext == 'docx') {
      mediaType = MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    } else {
      mediaType = MediaType('application', 'octet-stream');
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      file.bytes,
      filename: file.name,
      contentType: mediaType,
    );
  }

  void dispose() {
    _client.close();
  }
}




// lib/api/property_list_service.dart



class PropertyListService {
  final http.Client _client;

  PropertyListService({http.Client? client}) : _client = client ?? http.Client();

  /// Get all properties
  Future<PropertyListResponse> getProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get Properties List');
      print('URL: ${ApiUrls.propertyList}');

      final response = await _client.post(
        Uri.parse(ApiUrls.propertyList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Properties Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Approve a property
  Future<PropertyApproveResponse> approveProperty(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final request = PropertyApproveRequest(id: id);
      final requestBody = request.toJson();

      print('📤 Approve Property');
      print('URL: ${ApiUrls.propertyApprove}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.propertyApprove),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyApproveResponse.fromJson(jsonData);
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to approve property');
      }
    } catch (e) {
      print('❌ Approve Property Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}



// lib/api/builder_list_service.dart

//=====================schedule_meeting_service------------------------------------------



class ScheduleMeetingService {
  final http.Client _client;

  ScheduleMeetingService({http.Client? client}) : _client = client ?? http.Client();

  /// Schedule a meeting for a property enquiry
  Future<ScheduleMeetingResponse> scheduleMeeting(
      ScheduleMeetingRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final uri = Uri.parse(ApiUrls.scheduleMeeting);
      final body = jsonEncode(request.toJson());

      print('📤 Schedule Meeting');
      print('URL: $uri');
      print('Body: $body');

      final response = await _client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 60));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ScheduleMeetingResponse.fromJson(jsonDecode(response.body));
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to schedule meeting');
      }
    } catch (e) {
      print('❌ Schedule Meeting Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}

class BuilderListService {
  final http.Client _client;
  final BuilderService _builderService;

  BuilderListService({
    http.Client? client,
    BuilderService? builderService,
  })  : _client = client ?? http.Client(),
        _builderService = builderService ?? BuilderService();

  /// Create a new builder
  ///
  /// This wrapper is kept here because the create-property screen uses
  /// BuilderListService for both loading the builder list and creating a
  /// builder from the popup.
  Future<BuilderCreateResponse> createBuilder({
    required String name,
    required String shortInfo,
    Uint8List? logoBytes,
    String? logoFileName,
    String? website,
    String? email,
    String? phone,
    bool isActive = true,
  }) async {
    return _builderService.createBuilder(
      name: name,
      shortInfo: shortInfo,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      website: website,
      email: email,
      phone: phone,
      isActive: isActive,
    );
  }

  /// Get all builders
  Future<BuilderListResponse> getBuilders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get Builders List');
      print('URL: ${ApiUrls.buildersList}');

      final response = await _client.post(
        Uri.parse(ApiUrls.buildersList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return BuilderListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load builders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Builders Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}


// lib/api/property_enquiry_service.dart



class PropertyEnquiryService {
  final http.Client _client;

  PropertyEnquiryService({http.Client? client}) : _client = client ?? http.Client();

  /// Get all property enquiries
  Future<PropertyEnquiryResponse> getEnquiries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get Property Enquiries');
      print('URL: ${ApiUrls.propertyEnquiries}');

      final response = await _client.post(
        Uri.parse(ApiUrls.propertyEnquiries),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyEnquiryResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load property enquiries: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Property Enquiries Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }


  Future<PropertyEnquiryAssignResponse> assignEnquiry({
    required int enquiryId,
    required int channelPartnerId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final request = PropertyEnquiryAssignRequest(
        enquiryId: enquiryId,
        channelPartnerId: channelPartnerId,
      );

      print('📤 Assign Property Enquiry');
      print('URL: ${ApiUrls.propertyEnquiryAssign}');
      print('📤 Request Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.propertyEnquiryAssign),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyEnquiryAssignResponse.fromJson(jsonData);
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to assign enquiry');
      }
    } catch (e) {
      print('❌ Assign Enquiry Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// ✅ Get marketing partners for a specific enquiry
  /// Returns list of approved partners + the default assigned partner (property owner)
  Future<EnquiryWiseMarketingPartnersResponse> getEnquiryWiseMarketingPartners(
      int enquiryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get Enquiry-wise Marketing Partners');
      print('URL: ${ApiUrls.enquiryWiseMarketingPartners}');
      print('📤 Request Body: {"enquiry_id": $enquiryId}');

      final response = await _client.post(
        Uri.parse(ApiUrls.enquiryWiseMarketingPartners),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'enquiry_id': enquiryId}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return EnquiryWiseMarketingPartnersResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load partners: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Enquiry Partners Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}


// lib/api/channel_partner_service.dart



// lib/api/realestate_service.dart

class MarketingPartnerService {
  final http.Client _client;

  MarketingPartnerService({http.Client? client}) : _client = client ?? http.Client();

  /// Get all approved marketing partners
  Future<MarketingPartnerResponse> getApprovedMarketingPartners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get Approved Marketing Partners');
      print('URL: ${ApiUrls.approvedMarketingPartnersList}');

      final response = await _client.post(
        Uri.parse(ApiUrls.approvedMarketingPartnersList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return MarketingPartnerResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load marketing partners: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Marketing Partners Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}






// ==================== PDF EXTRACT SERVICE ====================
class PdfExtractService {
  final http.Client _client;

  PdfExtractService({http.Client? client}) : _client = client ?? http.Client();

  /// Upload PDF and extract property data
  Future<PdfExtractResponse> extractPropertyFromPdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.pdfExtractProperty);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';

      // PDF file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      print('📤 Extract Property from PDF');
      print('URL: $uri');
      print('File: $fileName (${pdfBytes.length} bytes)');

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 180));

      final response = await http.Response.fromStream(streamed);

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PdfExtractResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to extract PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ PDF Extract Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Download image from URL
  Future<Uint8List?> downloadImage(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('❌ Download image error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}





// services/real_estate/channel_partner_enquiry_service.dart




class ChannelPartnerEnquiryService {
  final http.Client _client;

  ChannelPartnerEnquiryService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetch channel partner enquiries
  Future<ChannelPartnerEnquiryResponse> fetchChannelPartnerEnquiries({
    required ChannelPartnerEnquiryRequest request,
    String? authToken,
  }) async {
    try {
      print('📤 Fetching Channel Partner Enquiries');
      print('URL: ${ApiUrls.channelPartnerEnquiries}');
      print('Request Body: ${jsonEncode(request.toJson())}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client.post(
        Uri.parse(ApiUrls.channelPartnerEnquiries),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 60));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ChannelPartnerEnquiryResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception(
            'Failed to load enquiries: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Channel Partner Enquiry Error: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}


//-------------------------my_properties_service--------------------------------------------------




class MyPropertiesService {
  final http.Client _client;

  MyPropertiesService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all my properties
  Future<MyPropertiesResponse> getMyProperties({
    MyPropertiesRequest? request,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Get My Properties');
      print('URL: ${ApiUrls.myProperties}');

      final body = request?.toJson() ?? {};
      print('📤 Request Body: ${jsonEncode(body)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.myProperties),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return MyPropertiesResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to load properties');
      }
    } catch (e) {
      print('❌ Get My Properties Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Update a property
  Future<PropertyUpdateResponse> updateProperty(PropertyUpdateRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Update Property');
      print('URL: ${ApiUrls.propertyUpdate}');
      print('📤 Request Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.propertyUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 60));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyUpdateResponse.fromJson(jsonData);
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update property');
      }
    } catch (e) {
      print('❌ Update Property Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}





//---------------------------------property_subscription_service---------------------------------------





class PropertySubscriptionService {
  final http.Client _client;

  PropertySubscriptionService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new property subscription plan
  Future<PropertySubscriptionCreateResponse> createPlan(
      PropertySubscriptionCreateRequest request) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiUrls.propertySubscriptionCreate);
      final body = jsonEncode(request.toJson());

      print('📤 Create Subscription Plan');
      print('URL: $uri');
      print('Body: $body');

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PropertySubscriptionCreateResponse.fromJson(
            jsonDecode(response.body));
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to create plan');
      }
    } catch (e) {
      print('❌ Create Plan Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Get list of all property subscription plans
  Future<PropertySubscriptionListResponse> getPlans() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiUrls.propertySubscriptionList);

      print('📤 Get Subscription Plans');
      print('URL: $uri');

      final response = await _client
          .post(uri, headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PropertySubscriptionListResponse.fromJson(
            jsonDecode(response.body));
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Plans Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Update a property subscription plan
  Future<PropertySubscriptionUpdateResponse> updatePlan(
      PropertySubscriptionUpdateRequest request) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiUrls.propertySubscriptionUpdate);
      final body = jsonEncode(request.toJson());

      print('📤 Update Subscription Plan');
      print('URL: $uri');
      print('Body: $body');

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PropertySubscriptionUpdateResponse.fromJson(
            jsonDecode(response.body));
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update plan');
      }
    } catch (e) {
      print('❌ Update Plan Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}