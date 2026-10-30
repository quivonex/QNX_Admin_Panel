/// Request model for updating bank details
class UpdateBankDetailsRequest {
  final int id;
  final String? accountHolderName;
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountType;
  final String? upiId;

  UpdateBankDetailsRequest({
    required this.id,
    this.accountHolderName,
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.ifscCode,
    this.accountType,
    this.upiId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (accountHolderName != null) 'account_holder_name': accountHolderName,
      if (bankName != null) 'bank_name': bankName,
      if (branchName != null) 'branch_name': branchName,
      if (accountNumber != null) 'account_number': accountNumber,
      if (ifscCode != null) 'ifsc_code': ifscCode,
      if (accountType != null) 'account_type': accountType,
      if (upiId != null) 'upi_id': upiId,
    };
  }
}