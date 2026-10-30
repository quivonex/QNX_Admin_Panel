// lib/models/ai_admin/ai_admin_model.dart

// ============================================================
// 1) DASHBOARD MODEL
// ============================================================
class AiDashboardData {
  final int totalConversations;
  final int totalMessages;
  final int totalUsers;
  final AiTodayData today;
  final AiMessagesStatus messages;
  final AiFeedbackData feedback;
  final List<AiServiceUsage> serviceUsage;

  AiDashboardData({
    required this.totalConversations,
    required this.totalMessages,
    required this.totalUsers,
    required this.today,
    required this.messages,
    required this.feedback,
    required this.serviceUsage,
  });

  factory AiDashboardData.fromJson(Map<String, dynamic> json) {
    return AiDashboardData(
      totalConversations: json['total_conversations'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      today: AiTodayData.fromJson(json['today'] ?? {}),
      messages: AiMessagesStatus.fromJson(json['messages'] ?? {}),
      feedback: AiFeedbackData.fromJson(json['feedback'] ?? {}),
      serviceUsage: (json['service_usage'] as List<dynamic>? ?? [])
          .map((e) => AiServiceUsage.fromJson(e))
          .toList(),
    );
  }
}

class AiTodayData {
  final int messages;
  final int conversations;

  AiTodayData({required this.messages, required this.conversations});

  factory AiTodayData.fromJson(Map<String, dynamic> json) {
    return AiTodayData(
      messages: json['messages'] ?? 0,
      conversations: json['conversations'] ?? 0,
    );
  }
}

class AiMessagesStatus {
  final int successful;
  final int failed;

  AiMessagesStatus({required this.successful, required this.failed});

  factory AiMessagesStatus.fromJson(Map<String, dynamic> json) {
    return AiMessagesStatus(
      successful: json['successful'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}

class AiFeedbackData {
  final int likes;
  final int dislikes;

  AiFeedbackData({required this.likes, required this.dislikes});

  factory AiFeedbackData.fromJson(Map<String, dynamic> json) {
    return AiFeedbackData(
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
    );
  }
}

class AiServiceUsage {
  final String service;
  final int count;

  AiServiceUsage({required this.service, required this.count});

  factory AiServiceUsage.fromJson(Map<String, dynamic> json) {
    return AiServiceUsage(
      service: json['service'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

// ============================================================
// 2) SETTINGS MODEL
// ============================================================
class AiSettingsData {
  final bool isEnabled;
  final int historyWindow;
  final int summaryThreshold;
  final int maxResultsPerQuery;
  final int maxMessageLength;
  final int dailyMessageLimit;
  final bool martEnabled;
  final bool remartEnabled;
  final bool realestateEnabled;
  final String? updatedAt;

  AiSettingsData({
    required this.isEnabled,
    required this.historyWindow,
    required this.summaryThreshold,
    required this.maxResultsPerQuery,
    required this.maxMessageLength,
    required this.dailyMessageLimit,
    required this.martEnabled,
    required this.remartEnabled,
    required this.realestateEnabled,
    this.updatedAt,
  });

  factory AiSettingsData.fromJson(Map<String, dynamic> json) {
    return AiSettingsData(
      isEnabled: json['is_enabled'] ?? false,
      historyWindow: json['history_window'] ?? 0,
      summaryThreshold: json['summary_threshold'] ?? 0,
      maxResultsPerQuery: json['max_results_per_query'] ?? 0,
      maxMessageLength: json['max_message_length'] ?? 0,
      dailyMessageLimit: json['daily_message_limit'] ?? 0,
      martEnabled: json['mart_enabled'] ?? false,
      remartEnabled: json['remart_enabled'] ?? false,
      realestateEnabled: json['realestate_enabled'] ?? false,
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'history_window': historyWindow,
      'summary_threshold': summaryThreshold,
      'max_results_per_query': maxResultsPerQuery,
      'max_message_length': maxMessageLength,
      'daily_message_limit': dailyMessageLimit,
      'mart_enabled': martEnabled,
      'remart_enabled': remartEnabled,
      'realestate_enabled': realestateEnabled,
    };
  }

  AiSettingsData copyWith({
    bool? isEnabled,
    int? historyWindow,
    int? summaryThreshold,
    int? maxResultsPerQuery,
    int? maxMessageLength,
    int? dailyMessageLimit,
    bool? martEnabled,
    bool? remartEnabled,
    bool? realestateEnabled,
  }) {
    return AiSettingsData(
      isEnabled: isEnabled ?? this.isEnabled,
      historyWindow: historyWindow ?? this.historyWindow,
      summaryThreshold: summaryThreshold ?? this.summaryThreshold,
      maxResultsPerQuery: maxResultsPerQuery ?? this.maxResultsPerQuery,
      maxMessageLength: maxMessageLength ?? this.maxMessageLength,
      dailyMessageLimit: dailyMessageLimit ?? this.dailyMessageLimit,
      martEnabled: martEnabled ?? this.martEnabled,
      remartEnabled: remartEnabled ?? this.remartEnabled,
      realestateEnabled: realestateEnabled ?? this.realestateEnabled,
      updatedAt: updatedAt,
    );
  }
}

// ============================================================
// 3) CONVERSATION MODELS
// ============================================================
class AiConversationUser {
  final int id;
  final String name;
  final String email;

  AiConversationUser({required this.id, required this.name, required this.email});

  factory AiConversationUser.fromJson(Map<String, dynamic> json) {
    return AiConversationUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AiConversationRow {
  final String id;
  final AiConversationUser user;
  final String title;
  final String activeService;
  final int messageCount;
  final bool isArchived;
  final bool isDeleted;
  final String lastMessageAt;
  final String createdAt;
  final String updatedAt;

  AiConversationRow({
    required this.id,
    required this.user,
    required this.title,
    required this.activeService,
    required this.messageCount,
    required this.isArchived,
    required this.isDeleted,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversationRow.fromJson(Map<String, dynamic> json) {
    return AiConversationRow(
      id: json['id']?.toString() ?? '',
      user: AiConversationUser.fromJson(json['user'] ?? {}),
      title: json['title'] ?? '',
      activeService: json['active_service'] ?? 'general',
      messageCount: json['message_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      lastMessageAt: json['last_message_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class AiConversationsListResponse {
  final int count;
  final List<AiConversationRow> results;

  AiConversationsListResponse({required this.count, required this.results});

  factory AiConversationsListResponse.fromJson(Map<String, dynamic> json) {
    return AiConversationsListResponse(
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => AiConversationRow.fromJson(e))
          .toList(),
    );
  }
}

// ============================================================
// 4) CONVERSATION DETAIL
// ============================================================
class AiConversationDetailResponse {
  final AiConversationRow? conversation;
  final List<AiMessage> messages;

  AiConversationDetailResponse({this.conversation, required this.messages});

  factory AiConversationDetailResponse.fromJson(Map<String, dynamic> json) {
    return AiConversationDetailResponse(
      conversation: json['conversation'] != null
          ? AiConversationRow.fromJson(json['conversation'])
          : null,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => AiMessage.fromJson(e))
          .toList(),
    );
  }
}

class AiMessage {
  final String id;
  final String role;
  final String content;
  final String status;
  final String? llmModel;
  final int? latencyMs;
  final int? feedback;
  final String createdAt;

  AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.status,
    this.llmModel,
    this.latencyMs,
    this.feedback,
    required this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id']?.toString() ?? '',
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      llmModel: json['llm_model'],
      latencyMs: json['latency_ms'],
      feedback: json['feedback'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// ============================================================
// 5) ANALYTICS
// ============================================================
class AiAnalyticsData {
  final AiAnalyticsPeriod? period;
  final List<AiDailyMessage> dailyMessages;
  final List<AiServiceUsage> serviceUsage;
  final AiFeedbackData? feedback;

  AiAnalyticsData({
    this.period,
    required this.dailyMessages,
    required this.serviceUsage,
    this.feedback,
  });

  factory AiAnalyticsData.fromJson(Map<String, dynamic> json) {
    return AiAnalyticsData(
      period: json['period'] != null
          ? AiAnalyticsPeriod.fromJson(json['period'])
          : null,
      dailyMessages: (json['daily_messages'] as List<dynamic>? ?? [])
          .map((e) => AiDailyMessage.fromJson(e))
          .toList(),
      serviceUsage: (json['service_usage'] as List<dynamic>? ?? [])
          .map((e) => AiServiceUsage.fromJson(e))
          .toList(),
      feedback: json['feedback'] != null
          ? AiFeedbackData.fromJson(json['feedback'])
          : null,
    );
  }
}

class AiAnalyticsPeriod {
  final String from;
  final String to;

  AiAnalyticsPeriod({required this.from, required this.to});

  factory AiAnalyticsPeriod.fromJson(Map<String, dynamic> json) {
    return AiAnalyticsPeriod(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }
}

class AiDailyMessage {
  final String date;
  final int count;

  AiDailyMessage({required this.date, required this.count});

  factory AiDailyMessage.fromJson(Map<String, dynamic> json) {
    return AiDailyMessage(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

// ============================================================
// 6) USAGE
// ============================================================
class AiUsageData {
  final int totalRequests;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final num averageLatencyMs;
  final List<AiModelUsage> models;

  AiUsageData({
    required this.totalRequests,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.averageLatencyMs,
    required this.models,
  });

  factory AiUsageData.fromJson(Map<String, dynamic> json) {
    return AiUsageData(
      totalRequests: json['total_requests'] ?? 0,
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
      averageLatencyMs: json['average_latency_ms'] ?? 0,
      models: (json['models'] as List<dynamic>? ?? [])
          .map((e) => AiModelUsage.fromJson(e))
          .toList(),
    );
  }
}

class AiModelUsage {
  final String llmModel;
  final int requests;
  final int promptTokens;
  final int completionTokens;

  AiModelUsage({
    required this.llmModel,
    required this.requests,
    required this.promptTokens,
    required this.completionTokens,
  });

  factory AiModelUsage.fromJson(Map<String, dynamic> json) {
    return AiModelUsage(
      llmModel: json['llm_model'] ?? '',
      requests: json['requests'] ?? 0,
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
    );
  }
}