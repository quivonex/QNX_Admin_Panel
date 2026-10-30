// lib/models/marketing_partner/partner_commission_list_model.dart

class PartnerCommissionListResponse {
  final bool status;
  final String message;
  final int count;
  final List<PartnerCommissionData> data;

  PartnerCommissionListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PartnerCommissionListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return PartnerCommissionListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: list.map((e) => PartnerCommissionData.fromJson(e)).toList(),
    );
  }
}

class PartnerCommissionData {
  final int marketingPartnerId;
  final String marketingPartner;

  PartnerCommissionData({
    required this.marketingPartnerId,
    required this.marketingPartner,
  });

  factory PartnerCommissionData.fromJson(Map<String, dynamic> json) {
    return PartnerCommissionData(
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartner: json['marketing_partner'] ?? '',
    );
  }
}