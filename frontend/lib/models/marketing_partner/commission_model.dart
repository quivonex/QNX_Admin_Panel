// lib/models/marketing_partner/commission_model.dart

class CommissionResponse {
  final bool status;
  final String message;
  final List<CommissionData> data;

  CommissionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CommissionResponse.fromJson(Map<String, dynamic> json) {
    List<CommissionData> commissionData = [];
    if (json['data'] != null && json['data'] is List) {
      commissionData = (json['data'] as List)
          .map((e) => CommissionData.fromJson(e))
          .toList();
    }
    return CommissionResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: commissionData,
    );
  }
}

class CommissionData {
  final int enquiryId;
  final String personName;
  final String email;
  final String contact;
  final String product;
  final List<CommissionDetail> commission;

  CommissionData({
    required this.enquiryId,
    required this.personName,
    required this.email,
    required this.contact,
    required this.product,
    required this.commission,
  });

  factory CommissionData.fromJson(Map<String, dynamic> json) {
    List<CommissionDetail> commissionList = [];
    if (json['commission'] != null && json['commission'] is List) {
      commissionList = (json['commission'] as List)
          .map((e) => CommissionDetail.fromJson(e))
          .toList();
    }
    return CommissionData(
      enquiryId: json['enquiry_id'] ?? 0,
      personName: json['person_name'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? '',
      product: json['product'] ?? '',
      commission: commissionList,
    );
  }

  // Calculate total commission amount
  double get totalCommissionAmount {
    double total = 0.0;
    for (var item in commission) {
      total += double.tryParse(item.amount) ?? 0.0;
    }
    return total;
  }

  // Get commission display string
  String get commissionDisplay {
    if (commission.isEmpty) return '₹0.00';
    return '₹${totalCommissionAmount.toStringAsFixed(2)}';
  }
}

class CommissionDetail {
  final String commissionType;
  final String percentage;
  final String amount;

  CommissionDetail({
    required this.commissionType,
    required this.percentage,
    required this.amount,
  });

  factory CommissionDetail.fromJson(Map<String, dynamic> json) {
    return CommissionDetail(
      commissionType: json['commission_type'] ?? '',
      percentage: json['percentage']?.toString() ?? '0',
      amount: json['amount']?.toString() ?? '0',
    );
  }
}