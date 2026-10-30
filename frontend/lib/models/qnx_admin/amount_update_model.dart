// lib/models/amount_update_model.dart

class AmountUpdateRequest {
  final String amount;

  AmountUpdateRequest({
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
    };
  }
}

class AmountUpdateResponse {
  final bool status;
  final String message;
  final AmountData? data;

  AmountUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AmountUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AmountUpdateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AmountData.fromJson(json['data']) : null,
    );
  }
}

class AmountData {
  final int id;
  final String amount;

  AmountData({
    required this.id,
    required this.amount,
  });

  factory AmountData.fromJson(Map<String, dynamic> json) {
    return AmountData(
      id: json['id'] ?? 0,
      amount: json['amount'] ?? '0',
    );
  }
}