// Paid Companies Count Response
class PaidCompanyCountResponse {
  final bool status;
  final String message;
  final int count;

  PaidCompanyCountResponse({
    required this.status,
    required this.message,
    required this.count,
  });

  factory PaidCompanyCountResponse.fromJson(Map<String, dynamic> json) {
    return PaidCompanyCountResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

// Unpaid Companies Pending Amount Response
class UnpaidCompanyPendingAmountResponse {
  final bool status;
  final String message;
  final int unpaidCompanyCount;
  final int registrationAmount;
  final int totalPendingAmount;

  UnpaidCompanyPendingAmountResponse({
    required this.status,
    required this.message,
    required this.unpaidCompanyCount,
    required this.registrationAmount,
    required this.totalPendingAmount,
  });

  factory UnpaidCompanyPendingAmountResponse.fromJson(Map<String, dynamic> json) {
    return UnpaidCompanyPendingAmountResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      unpaidCompanyCount: json['unpaid_company_count'] ?? 0,
      registrationAmount: json['registration_amount'] ?? 0,
      totalPendingAmount: json['total_pending_amount'] ?? 0,
    );
  }
}