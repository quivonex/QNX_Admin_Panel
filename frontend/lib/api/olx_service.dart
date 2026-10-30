// lib/api/olx_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_url.dart';
import '../models/olx/olx_category_model.dart';
import '../models/olx/olx_subcategory_model.dart';
import '../models/olx/olx_plan_model.dart';
import '../models/olx/olx_pricing_model.dart';
import '../models/olx/olx_attribute_model.dart';
import '../models/olx/olx_settings_model.dart';
import '../models/olx/olx_communication_plan_model.dart';
import '../models/olx/olx_communication_settings_model.dart';

class OlxCategoryService {
  final http.Client _client;

  OlxCategoryService({http.Client? client}) : _client = client ?? http.Client();

  // ==================== CATEGORY APIs ====================

  /// Create OLX Category
  Future<OlxCategoryResponse> createCategory(OlxCategoryRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCategoryCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Category Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxCategoryResponse.fromJson(jsonData);
      } else {
        return OlxCategoryResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create category',
        );
      }
    } catch (e) {
      print('❌ Create OLX Category Error: $e');
      return OlxCategoryResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Get All OLX Categories
  Future<OlxCategoryListResponse> getCategories() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCategoryList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📤 OLX Category List');
      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxCategoryListResponse.fromJson(jsonData);
      } else {
        return OlxCategoryListResponse(success: false, data: []);
      }
    } catch (e) {
      print('❌ Get OLX Categories Error: $e');
      return OlxCategoryListResponse(success: false, data: []);
    }
  }

  // ==================== SUB-CATEGORY APIs ====================

  /// Create OLX Sub-Category
  /// POST http://0.0.0.0:16000/olx/subcategories/create/
  Future<OlxSubcategoryCreateResponse> createSubcategory(
      OlxSubcategoryRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxSubcategoryCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Subcategory Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxSubcategoryCreateResponse.fromJson(jsonData);
      } else {
        return OlxSubcategoryCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create subcategory',
        );
      }
    } catch (e) {
      print('❌ Create OLX Subcategory Error: $e');
      return OlxSubcategoryCreateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Get OLX Sub-Categories by Category ID
  /// POST http://0.0.0.0:16000/olx/subcategories/
  Future<OlxSubcategoryListResponse> getSubcategories(int categoryId) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxSubcategoryList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'category_id': categoryId}),
      );

      print('📤 OLX Subcategory List for Category: $categoryId');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxSubcategoryListResponse.fromJson(jsonData);
      } else {
        return OlxSubcategoryListResponse(
          success: false,
          message: 'Failed to load subcategories',
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get OLX Subcategories Error: $e');
      return OlxSubcategoryListResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}



// lib/api/olx_plan_pricing_service.dart



class OlxPlanPricingService {
  final http.Client _client;

  OlxPlanPricingService({http.Client? client})
      : _client = client ?? http.Client();

  // ================================================================
  // ✅ 1. CREATE PLAN
  // POST http://0.0.0.0:16000/olx/plans/create/
  // ================================================================
  Future<OlxPlanCreateResponse> createPlan(OlxPlanRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxPlanCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Plan Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxPlanCreateResponse.fromJson(jsonData);
      } else {
        return OlxPlanCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create plan',
        );
      }
    } catch (e) {
      print('❌ Create OLX Plan Error: $e');
      return OlxPlanCreateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 2. GET ALL PLANS
  // POST http://0.0.0.0:16000/olx/plans/
  // ================================================================
  Future<OlxPlanListResponse> getPlans() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxPlanList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📤 OLX Plan List');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxPlanListResponse.fromJson(jsonData);
      } else {
        return OlxPlanListResponse(success: false, data: []);
      }
    } catch (e) {
      print('❌ Get OLX Plans Error: $e');
      return OlxPlanListResponse(success: false, data: []);
    }
  }

  // ================================================================
  // ✅ 3. CREATE PRICING
  // POST http://0.0.0.0:16000/olx/pricing/create/
  // ================================================================
  Future<OlxPricingCreateResponse> createPricing(
      OlxPricingRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxPricingCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Pricing Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxPricingCreateResponse.fromJson(jsonData);
      } else {
        return OlxPricingCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create pricing',
        );
      }
    } catch (e) {
      print('❌ Create OLX Pricing Error: $e');
      return OlxPricingCreateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 4. GET PRICING BY PLAN
  // POST http://0.0.0.0:16000/olx/pricing/plans/
  // ================================================================
  Future<OlxPricingListResponse> getPricingByPlan(int planId) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxPricingListByPlan),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'plan_id': planId}),
      );

      print('📤 OLX Pricing List for Plan ID: $planId');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxPricingListResponse.fromJson(jsonData);
      } else {
        return OlxPricingListResponse(
          success: false,
          message: 'Failed to load pricing',
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get OLX Pricing Error: $e');
      return OlxPricingListResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}


// ==================== OLX ATTRIBUTE SERVICE ====================
class OlxAttributeService {
  final http.Client _client;

  OlxAttributeService({http.Client? client})
      : _client = client ?? http.Client();

  // ================================================================
  // ✅ 1. CREATE ATTRIBUTE
  // POST http://0.0.0.0:16000/olx/attributes/create/
  // ================================================================
  Future<OlxAttributeCreateResponse> createAttribute(
      OlxAttributeRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxAttributeCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Attribute Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxAttributeCreateResponse.fromJson(jsonData);
      } else {
        return OlxAttributeCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create attribute',
        );
      }
    } catch (e) {
      print('❌ Create OLX Attribute Error: $e');
      return OlxAttributeCreateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 2. GET ATTRIBUTES BY CATEGORY + SUBCATEGORY
  // POST http://0.0.0.0:16000/olx/attributes/
  // ================================================================
  Future<OlxAttributeListResponse> getAttributes({
    required int categoryId,
    required int subcategoryId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxAttributeList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'category_id': categoryId,
          'subcategory_id': subcategoryId,
        }),
      );

      print('📤 OLX Attribute List: cat=$categoryId, sub=$subcategoryId');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxAttributeListResponse.fromJson(jsonData);
      } else {
        return OlxAttributeListResponse(
          success: false,
          message: 'Failed to load attributes',
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get OLX Attributes Error: $e');
      return OlxAttributeListResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

//---------------------------olx_settings_service--------------------------------------------------------
// lib/api/olx_settings_service.dart


class OlxSettingsService {
  final http.Client _client;

  OlxSettingsService({http.Client? client}) : _client = client ?? http.Client();

  // ================================================================
  // ✅ 1. CREATE SETTINGS
  // POST http://0.0.0.0:16000/olx/settings/create/
  // ================================================================
  Future<OlxSettingsCreateResponse> createSettings(
      OlxSettingsCreateRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxSettingsCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Settings Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxSettingsCreateResponse.fromJson(jsonData);
      } else {
        return OlxSettingsCreateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to create settings',
        );
      }
    } catch (e) {
      print('❌ Create OLX Settings Error: $e');
      return OlxSettingsCreateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 2. UPDATE SETTINGS
  // POST http://0.0.0.0:16000/olx/settings/update/
  // ================================================================
  Future<OlxSettingsUpdateResponse> updateSettings(
      OlxSettingsUpdateRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxSettingsUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Settings Update: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxSettingsUpdateResponse.fromJson(jsonData);
      } else {
        return OlxSettingsUpdateResponse(
          success: false,
          message: jsonData['message'] ?? 'Failed to update settings',
        );
      }
    } catch (e) {
      print('❌ Update OLX Settings Error: $e');
      return OlxSettingsUpdateResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 3. GET SETTINGS (with optional id filter)
  // POST http://0.0.0.0:16000/olx/settings/
  // ================================================================
  Future<OlxSettingsListResponse> getSettings({int? id}) async {
    try {
      final Map<String, dynamic> body = {};
      if (id != null) {
        body['id'] = id;
      }

      final response = await _client.post(
        Uri.parse(ApiUrls.olxSettingsList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📤 OLX Settings Get: ${body.isEmpty ? "all" : body}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxSettingsListResponse.fromJson(jsonData);
      } else {
        return OlxSettingsListResponse(
          success: false,
          message: 'Failed to load settings',
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get OLX Settings Error: $e');
      return OlxSettingsListResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

//-----------------------olx_communication_plan_service------------------------------------------------




class OlxCommunicationPlanService {
  final http.Client _client;

  OlxCommunicationPlanService({http.Client? client})
      : _client = client ?? http.Client();

  // ================================================================
  // ✅ 1. CREATE COMMUNICATION PLAN
  // POST /olx/bazaar-communication-plans/create/
  // ================================================================
  Future<OlxCommunicationPlanCreateResponse> createPlan(
      OlxCommunicationPlanCreateRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCommunicationPlanCreate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Communication Plan Create: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxCommunicationPlanCreateResponse.fromJson(jsonData);
      } else {
        return OlxCommunicationPlanCreateResponse(
          status: false,
          message: jsonData['message'] ?? 'Failed to create communication plan',
        );
      }
    } catch (e) {
      print('❌ Create OLX Communication Plan Error: $e');
      return OlxCommunicationPlanCreateResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 2. LIST COMMUNICATION PLANS
  // POST /olx/bazaar-communication-plans/list/
  // ================================================================
  Future<OlxCommunicationPlanListResponse> getPlans({
    bool includeInactive = true,
  }) async {
    try {
      final request = OlxCommunicationPlanListRequest(
        includeInactive: includeInactive,
      );

      final response = await _client.post(
        Uri.parse(ApiUrls.olxCommunicationPlanList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Communication Plan List: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return OlxCommunicationPlanListResponse.fromJson(jsonData);
      } else {
        return OlxCommunicationPlanListResponse(
          success: false,
          count: 0,
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get OLX Communication Plans Error: $e');
      return OlxCommunicationPlanListResponse(
        success: false,
        count: 0,
        data: [],
      );
    }
  }

  // ================================================================
  // ✅ 3. UPDATE COMMUNICATION PLAN
  // POST /olx/bazaar-communication-plans/update/
  // ================================================================
  Future<OlxCommunicationPlanUpdateResponse> updatePlan(
      OlxCommunicationPlanUpdateRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCommunicationPlanUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Communication Plan Update: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxCommunicationPlanUpdateResponse.fromJson(jsonData);
      } else {
        return OlxCommunicationPlanUpdateResponse(
          status: false,
          message: jsonData['message'] ?? 'Failed to update communication plan',
        );
      }
    } catch (e) {
      print('❌ Update OLX Communication Plan Error: $e');
      return OlxCommunicationPlanUpdateResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}


//----------------------olx_communication_settings_service------------------------------------------------


class OlxCommunicationSettingsService {
  final http.Client _client;

  OlxCommunicationSettingsService({http.Client? client})
      : _client = client ?? http.Client();

  // ================================================================
  // ✅ 1. GET COMMUNICATION SETTINGS DETAIL
  // POST /olx/bazaar-communication-settings/detail/
  // ================================================================
  Future<OlxCommunicationSettingsDetailResponse> getSettings() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCommunicationSettingsDetail),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📤 OLX Communication Settings Detail');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxCommunicationSettingsDetailResponse.fromJson(jsonData);
      } else {
        return OlxCommunicationSettingsDetailResponse(
          status: false,
          message: jsonData['message'] ?? 'Failed to fetch settings',
        );
      }
    } catch (e) {
      print('❌ Get OLX Communication Settings Error: $e');
      return OlxCommunicationSettingsDetailResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // ================================================================
  // ✅ 2. UPDATE COMMUNICATION SETTINGS
  // POST /olx/bazaar-communication-settings/update/
  // ================================================================
  Future<OlxCommunicationSettingsUpdateResponse> updateSettings(
      OlxCommunicationSettingsUpdateRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.olxCommunicationSettingsUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 OLX Communication Settings Update: ${request.toJson()}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OlxCommunicationSettingsUpdateResponse.fromJson(jsonData);
      } else {
        return OlxCommunicationSettingsUpdateResponse(
          status: false,
          message: jsonData['message'] ?? 'Failed to update settings',
        );
      }
    } catch (e) {
      print('❌ Update OLX Communication Settings Error: $e');
      return OlxCommunicationSettingsUpdateResponse(
        status: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}