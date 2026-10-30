// lib/models/marketing_partner/wallet_model.dart

class WalletResponse {
  final bool status;
  final String message;
  final WalletData? data;

  WalletResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? WalletData.fromJson(json['data']) : null,
    );
  }
}

class WalletData {
  final int marketingPartnerId;
  final String marketingPartnerName;
  final String balance;
  final String totalEarned;
  final String totalWithdrawn;

  WalletData({
    required this.marketingPartnerId,
    required this.marketingPartnerName,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartnerName: json['marketing_partner_name'] ?? '',
      balance: json['balance']?.toString() ?? '0.00',
      totalEarned: json['total_earned']?.toString() ?? '0.00',
      totalWithdrawn: json['total_withdrawn']?.toString() ?? '0.00',
    );
  }

  double get balanceDouble => double.tryParse(balance) ?? 0.0;
  double get totalEarnedDouble => double.tryParse(totalEarned) ?? 0.0;
  double get totalWithdrawnDouble => double.tryParse(totalWithdrawn) ?? 0.0;
}

class WithdrawResponse {
  final bool status;
  final String message;
  final WithdrawData? data;

  WithdrawResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? WithdrawData.fromJson(json['data']) : null,
    );
  }
}

class WithdrawData {
  final int requestId;
  final String requestedAmount;
  final String status;
  final String walletBalance;

  WithdrawData({
    required this.requestId,
    required this.requestedAmount,
    required this.status,
    required this.walletBalance,
  });

  factory WithdrawData.fromJson(Map<String, dynamic> json) {
    return WithdrawData(
      requestId: json['request_id'] ?? 0,
      requestedAmount: json['requested_amount']?.toString() ?? '0',
      status: json['status'] ?? 'pending',
      walletBalance: json['wallet_balance']?.toString() ?? '0',
    );
  }
}

