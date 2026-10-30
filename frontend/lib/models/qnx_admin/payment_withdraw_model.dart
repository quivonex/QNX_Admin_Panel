// lib/models/payment_withdraw_model.dart

class PaymentWithdrawResponse {
  final bool status;
  final String message;
  final PaymentWithdrawData? data;

  PaymentWithdrawResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PaymentWithdrawResponse.fromJson(Map<String, dynamic> json) {
    return PaymentWithdrawResponse(
      status: json['status'] == true || json['status'] == 'true',
      message: json['message'] ?? '',
      data: json['data'] != null && json['data'] is Map
          ? PaymentWithdrawData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class PaymentWithdrawData {
  final int requestId;
  final String marketingPartner;
  final String paidAmount;
  final String remainingBalance;
  final String status;
  final String paymentMethod;
  final PaidBy? paidBy;
  final String? paidByName;

  PaymentWithdrawData({
    required this.requestId,
    required this.marketingPartner,
    required this.paidAmount,
    required this.remainingBalance,
    required this.status,
    required this.paymentMethod,
    this.paidBy,
    this.paidByName,
  });

  factory PaymentWithdrawData.fromJson(Map<String, dynamic> json) {
    return PaymentWithdrawData(
      requestId: json['request_id'] ?? 0,
      marketingPartner: json['marketing_partner'] ?? '',
      paidAmount: _parseAmount(json['paid_amount']),
      remainingBalance: _parseAmount(json['remaining_balance']),
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? 'upi',
      paidBy: json['paid_by'] != null && json['paid_by'] is Map
          ? PaidBy.fromJson(json['paid_by'])
          : null,
      paidByName: json['paid_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'marketing_partner': marketingPartner,
      'paid_amount': paidAmount,
      'remaining_balance': remainingBalance,
      'status': status,
      'payment_method': paymentMethod,
      'paid_by': paidBy?.toJson(),
      'paid_by_name': paidByName,
    };
  }

  static String _parseAmount(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toString();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return cleaned.isEmpty ? '0' : cleaned;
    }
    return '0';
  }

  double get paidAmountDouble => double.tryParse(paidAmount) ?? 0.0;
  double get remainingBalanceDouble => double.tryParse(remainingBalance) ?? 0.0;
  bool get isPaid => status.toLowerCase() == 'paid';
}

class PaidBy {
  final int id;
  final String username;
  final String name;

  PaidBy({
    required this.id,
    required this.username,
    required this.name,
  });

  factory PaidBy.fromJson(Map<String, dynamic> json) {
    return PaidBy(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
    };
  }
}