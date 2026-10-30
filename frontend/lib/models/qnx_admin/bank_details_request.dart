import '../../api/api_response.dart';

class BankDetailsRequest {
  final int marketingPartner;
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType; // 'savings' or 'current'
  final String? upiId;


  BankDetailsRequest({
    required this.marketingPartner,
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    this.upiId,
  });

  Map<String, dynamic> toJson() {
    return {
      'marketing_partner': marketingPartner,
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'branch_name': branchName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_type': accountType,
      if (upiId != null && upiId!.isNotEmpty) 'upi_id': upiId,
    };
  }
}

class BankDetail {
  final int id;
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String? upiId;
  final String createdAt;
  final int marketingPartner;

  BankDetail({
    required this.id,
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    this.upiId,
    required this.createdAt,
    required this.marketingPartner,
  });

  factory BankDetail.fromJson(Map<String, dynamic> json) {
    return BankDetail(
      id: json['id'] ?? 0,
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'] ?? '',
      upiId: json['upi_id'],
      createdAt: json['created_at'] ?? '',
      marketingPartner: json['marketing_partner'] ?? 0,
    );
  }
}

class RetrieveBankDetailsResponse {
  final bool status;
  final String message;
  final BankDetailsData? data;

  RetrieveBankDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory RetrieveBankDetailsResponse.fromJson(
      Map<String, dynamic> json) {
    return RetrieveBankDetailsResponse(
      status: json["status"],
      message: json["message"],
      data: json["data"] != null
          ? BankDetailsData.fromJson(json["data"])
          : null,
    );
  }
}

class RetrieveBankDetailsRequest {
  final int marketingPartner;

  RetrieveBankDetailsRequest({
    required this.marketingPartner,
  });

  Map<String, dynamic> toJson() {
    return {
      "marketing_partner": marketingPartner,
    };
  }
}