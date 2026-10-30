class BankDetailsRequest {
  final int marketingPartner;
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
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
      "marketing_partner": marketingPartner,
      "account_holder_name": accountHolderName,
      "bank_name": bankName,
      "branch_name": branchName,
      "account_number": accountNumber,
      "ifsc_code": ifscCode,
      "account_type": accountType,
      "upi_id": upiId,
    };
  }
}