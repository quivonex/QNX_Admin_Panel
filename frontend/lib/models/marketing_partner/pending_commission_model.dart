// lib/models/marketing_partner/pending_commission_model.dart

class PendingCommissionResponse {
  final bool status;
  final int? marketingPartnerId;
  final String? marketingPartnerName;
  final String? totalPendingCommission;
  final int? totalPendingEnquiries;
  final List<PendingCommissionItem> data;

  PendingCommissionResponse({
    required this.status,
    this.marketingPartnerId,
    this.marketingPartnerName,
    this.totalPendingCommission,
    this.totalPendingEnquiries,
    required this.data,
  });

  factory PendingCommissionResponse.fromJson(Map<String, dynamic> json) {
    return PendingCommissionResponse(
      status: json['status'] ?? false,
      marketingPartnerId: json['marketing_partner_id'],
      marketingPartnerName: json['marketing_partner_name'],
      totalPendingCommission: json['total_pending_commission'],
      totalPendingEnquiries: json['total_pending_enquiries'],
      data: (json['data'] as List? ?? [])
          .map((e) => PendingCommissionItem.fromJson(e))
          .toList(),
    );
  }
}

class PendingCommissionItem {
  final int enquiryId;
  final String personName;
  final String productName;
  final String companyName;
  final String companyPhoneNumber;
  final String companyAmount;
  final String profitSharePercentage;
  final String commission;

  PendingCommissionItem({
    required this.enquiryId,
    required this.personName,
    required this.productName,
    required this.companyName,
    required this.companyPhoneNumber,
    required this.companyAmount,
    required this.profitSharePercentage,
    required this.commission,
  });

  factory PendingCommissionItem.fromJson(Map<String, dynamic> json) {
    return PendingCommissionItem(
      enquiryId: json['enquiry_id'] ?? 0,
      personName: json['person_name'] ?? '',
      productName: json['product_name'] ?? '',
      companyName: json['company_name'] ?? '',
      companyPhoneNumber: json['company_phone_number'] ?? '',
      companyAmount: json['company_amount'] ?? '0.00',
      profitSharePercentage: json['profit_share_percentage'] ?? '0.00',
      commission: json['commission'] ?? '0.00',
    );
  }
}