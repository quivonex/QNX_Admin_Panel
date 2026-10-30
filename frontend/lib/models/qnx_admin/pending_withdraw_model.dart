// lib/models/marketing_partner/pending_withdraw_model.dart

class PendingWithdrawResponse {
  final bool status;
  final String message;
  final int count;
  final List<PendingWithdrawData> data;

  PendingWithdrawResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PendingWithdrawResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return PendingWithdrawResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: list.map((e) => PendingWithdrawData.fromJson(e)).toList(),
    );
  }
}

class PendingWithdrawData {
  final int requestId;
  final int marketingPartnerId;
  final String marketingPartner;
  final int walletId;
  final String amount;
  final String status;
  final String? remarks;
  final String createdAt;
  final String updatedAt;

  PendingWithdrawData({
    required this.requestId,
    required this.marketingPartnerId,
    required this.marketingPartner,
    required this.walletId,
    required this.amount,
    required this.status,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingWithdrawData.fromJson(Map<String, dynamic> json) {
    return PendingWithdrawData(
      requestId: json['request_id'] ?? 0,
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartner: json['marketing_partner'] ?? '',
      walletId: json['wallet_id'] ?? 0,
      amount: json['amount']?.toString() ?? '0',
      status: json['status'] ?? '',
      remarks: json['remarks'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  double get amountDouble => double.tryParse(amount) ?? 0.0;
}