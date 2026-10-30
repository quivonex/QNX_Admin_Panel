// lib/api/ai_admin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_url.dart';
import '../models/ai_admin/ai_admin_model.dart';

class AiAdminService {
  final http.Client _client;

  AiAdminService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // ============================================================
  // 1) DASHBOARD
  // ============================================================
  Future<AiDashboardData?> getDashboard({String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse(ApiUrls.aiAdminDashboard),
        headers: _headers(token),
      );

      print('📤 AI Dashboard → ${res.statusCode}');
      print('📦 ${res.body}');

      if (res.statusCode == 200) {
        return AiDashboardData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Dashboard Error: $e');
      return null;
    }
  }

  // ============================================================
  // 2) GET SETTINGS
  // ============================================================
  Future<AiSettingsData?> getSettings({String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse(ApiUrls.aiAdminSettings),
        headers: _headers(token),
      );

      print('📤 AI Settings → ${res.statusCode}');
      print('📦 ${res.body}');

      if (res.statusCode == 200) {
        return AiSettingsData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Settings Error: $e');
      return null;
    }
  }

  // ============================================================
  // 3) UPDATE SETTINGS (PATCH — partial)
  // ============================================================
  Future<AiSettingsData?> updateSettings(
      AiSettingsData payload,
      {String? token}) async {
    try {
      final res = await _client.patch(
        Uri.parse(ApiUrls.aiAdminSettings),
        headers: _headers(token),
        body: jsonEncode(payload.toJson()),
      );

      print('📤 AI Settings Update: ${payload.toJson()}');
      print('📥 Status: ${res.statusCode}');
      print('📦 ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return AiSettingsData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Settings Update Error: $e');
      return null;
    }
  }

  // ============================================================
  // 4) LIST CONVERSATIONS
  // ============================================================
  Future<AiConversationsListResponse?> getConversations({
    String? search,
    String? service,
    bool? isArchived,
    bool? isDeleted,
    int? userId,
    int page = 1,
    int pageSize = 20,
    String? token,
  }) async {
    try {
      final q = <String>[];
      if (search != null && search.isNotEmpty) {
        q.add('search=${Uri.encodeComponent(search)}');
      }
      if (service != null && service.isNotEmpty) q.add('service=$service');
      if (isArchived != null) q.add('is_archived=$isArchived');
      if (isDeleted != null) q.add('is_deleted=$isDeleted');
      if (userId != null) q.add('user_id=$userId');
      q.add('page=$page');
      q.add('page_size=$pageSize');

      final url = '${ApiUrls.aiAdminConversations}?${q.join('&')}';

      final res = await _client.get(Uri.parse(url), headers: _headers(token));

      print('📤 AI Conversations → ${res.statusCode}');
      print('📦 ${res.body}');

      if (res.statusCode == 200) {
        return AiConversationsListResponse.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Conversations Error: $e');
      return null;
    }
  }

  // ============================================================
  // 5) CONVERSATION DETAIL
  // ============================================================
  Future<AiConversationDetailResponse?> getConversationDetail(
      String conversationId,
      {String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse('${ApiUrls.aiAdminConversations}$conversationId/'),
        headers: _headers(token),
      );

      print('📤 AI Conv Detail → ${res.statusCode}');

      if (res.statusCode == 200) {
        return AiConversationDetailResponse.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Conv Detail Error: $e');
      return null;
    }
  }

  // ============================================================
  // 6) MESSAGE DETAIL
  // ============================================================
  Future<Map<String, dynamic>?> getMessageDetail(String messageId,
      {String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse('${ApiUrls.aiAdminMessages}$messageId/'),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ AI Message Detail Error: $e');
      return null;
    }
  }

  // ============================================================
  // 7) ANALYTICS (days = 7 | 30 | 90)
  // ============================================================
  Future<AiAnalyticsData?> getAnalytics({int days = 7, String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse('${ApiUrls.aiAdminAnalytics}?days=$days'),
        headers: _headers(token),
      );

      print('📤 AI Analytics → ${res.statusCode}');

      if (res.statusCode == 200) {
        return AiAnalyticsData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Analytics Error: $e');
      return null;
    }
  }

  // ============================================================
  // 8) USAGE
  // ============================================================
  Future<AiUsageData?> getUsage({String? token}) async {
    try {
      final res = await _client.get(
        Uri.parse(ApiUrls.aiAdminUsage),
        headers: _headers(token),
      );

      print('📤 AI Usage → ${res.statusCode}');

      if (res.statusCode == 200) {
        return AiUsageData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('❌ AI Usage Error: $e');
      return null;
    }
  }

  void dispose() => _client.close();
}