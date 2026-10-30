// lib/api/shiprocket_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shiprocket/prepaid_cancelled_order_model.dart';
import '../models/shiprocket/return_shipment_model.dart';
import '../models/shiprocket/shiprocket_model.dart';
import 'api_url.dart';
import '../models/shiprocket/shipment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_url.dart';
import '../models/shiprocket/return_order_model.dart';



class ShiprocketService {
  final http.Client _client;

  ShiprocketService({http.Client? client}) : _client = client ?? http.Client();

  /// Get all ship orders
  Future<ShipOrdersResponse> getShipOrders() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.shipOrders),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📡 Ship Orders API Status: ${response.statusCode}');
      print('📦 Ship Orders Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ShipOrdersResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load ship orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ship Orders Error: $e');
      throw Exception('Error fetching ship orders: $e');
    }
  }

  /// Create Shiprocket order
  Future<ShiprocketCreateOrderResponse> createShiprocketOrder(int orderId) async {
    try {
      final request = ShiprocketCreateOrderRequest(orderId: orderId);

      final response = await _client.post(
        Uri.parse(ApiUrls.shiprocketCreateOrder),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 Create Shiprocket Order Request: ${request.toJson()}');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ShiprocketCreateOrderResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to create shiprocket order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Create Shiprocket Order Error: $e');
      throw Exception('Error creating shiprocket order: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

//---------------------------shipment_service----------------------------------------------------

class ShipmentService {
  final http.Client _client;

  ShipmentService({http.Client? client}) : _client = client ?? http.Client();

  /// Get authentication token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  /// Get all shipments list
  Future<ShipmentListResponse> getShipments() async {
    try {
      final token = await _getToken();

      final response = await _client.post(
        Uri.parse(ApiUrls.shipmentList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Shipment List API Status: ${response.statusCode}');
      print('📦 Shipment List Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ShipmentListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load shipments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Shipment List Error: $e');
      throw Exception('Error fetching shipments: $e');
    }
  }

  /// Assign AWB to shipment - Only needs shipment_id (simplified API)
  /// API: POST /shiprocket/assign-awb/
  /// Body: { "shipment_id": "1512336635" }
  Future<AssignAWBResponse> assignAWB({
    required String shipmentId,
  }) async {
    try {
      final token = await _getToken();

      // Request only contains shipment_id
      final request = AssignAWBRequest(
        shipmentId: shipmentId,
      );

      final response = await _client.post(
        Uri.parse(ApiUrls.assignAWB),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 Assign AWB Request: ${request.toJson()}');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return AssignAWBResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to assign AWB: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Assign AWB Error: $e');
      throw Exception('Error assigning AWB: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// lib/api/return_order_service.dart


class ReturnOrderService {
  final http.Client _client;

  ReturnOrderService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all return orders
  Future<ReturnOrderListResponse> getReturnOrders() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.returnOrdersList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📡 Return Orders API Status: ${response.statusCode}');
      print('📦 Return Orders Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ReturnOrderListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load return orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Return Orders Error: $e');
      throw Exception('Error fetching return orders: $e');
    }
  }

  /// Create return shipment using return_id
  /// ⚠️ IMPORTANT: Does NOT throw — always returns response object
  Future<CreateReturnShipmentResponse> createReturnShipment({
    required int returnId,
  }) async {
    try {
      // ✅ Validation
      if (returnId <= 0) {
        print('❌ Invalid returnId: $returnId');
        return CreateReturnShipmentResponse(
          success: false,
          message: 'Invalid return ID: $returnId',
        );
      }

      final request = CreateReturnShipmentRequest(
        returnId: returnId.toString(),
      );

      print('📤 Create Return Shipment — return_id: $returnId');
      print('📤 URL: ${ApiUrls.createReturnShipment}');
      print('📤 Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.createReturnShipment),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      // ✅ 200/201 दोन्ही success — 404 सुद्धा parse करा
      final jsonData = jsonDecode(response.body);
      return CreateReturnShipmentResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Create Return Shipment Error: $e');
      return CreateReturnShipmentResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

// lib/api/return_shipment_service.dart

class ReturnShipmentService {
  final http.Client _client;

  ReturnShipmentService({http.Client? client}) : _client = client ?? http.Client();

  /// ✅ Fetch return shipment list (already shipment created ones)
  Future<ReturnShipmentListResponse> getReturnShipments() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiUrls.returnShipmentList),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      print('📡 Return Shipments API Status: ${response.statusCode}');
      print('📦 Return Shipments Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ReturnShipmentListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load return shipments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Return Shipments Error: $e');
      throw Exception('Error fetching return shipments: $e');
    }
  }

  /// ✅ Assign AWB using return_id
  /// ⚠️ Does NOT throw — returns response object
  Future<AssignReturnAWBResponse> assignReturnAWB({
    required int returnId,
  }) async {
    try {
      if (returnId <= 0) {
        return AssignReturnAWBResponse(
          success: false,
          message: 'Invalid return ID: $returnId',
        );
      }

      final request = AssignReturnAWBRequest(returnId: returnId.toString());

      print('📤 Assign Return AWB — return_id: $returnId');
      print('📤 URL: ${ApiUrls.assignReturnAWB}');
      print('📤 Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.assignReturnAWB),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      final jsonData = jsonDecode(response.body);
      return AssignReturnAWBResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ Assign Return AWB Error: $e');
      return AssignReturnAWBResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _client.close();

  }
}

// lib/api/shiprocket_service.dart

// ... existing services (ShiprocketService, ShipmentService, ReturnOrderService, ReturnShipmentService) ...

// ==================== PREPAID CANCELLED ORDERS SERVICE ====================
class PrepaidCancelledOrdersService {
  final http.Client _client;

  PrepaidCancelledOrdersService({http.Client? client})
      : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  /// POST → fetch all prepaid cancelled orders
  Future<PrepaidCancelledOrdersResponse> getPrepaidCancelledOrders() async {
    try {
      final token = await _getToken();
      final request = const PrepaidCancelledOrdersRequest();

      final response = await _client.post(
        Uri.parse(ApiUrls.prepaidCancelledOrders),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📡 Prepaid Cancelled Orders Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PrepaidCancelledOrdersResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load prepaid cancelled orders: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Prepaid Cancelled Orders Error: $e');
      throw Exception('Error fetching prepaid cancelled orders: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}