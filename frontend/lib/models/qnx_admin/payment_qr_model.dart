// lib/models/marketing_partner/payment_qr_model.dart

class PaymentQRResponse {
  final bool status;
  final String message;
  final int marketingPartnerId;
  final String marketingPartner;
  final String? upiId;
  final String amount;
  final String qrImage;
  final String upiLink;
  final String paymentMethod;
  final BankDetails? bankDetails;
  final String? chequeUploadUrl; // ✅ नवीन field

  PaymentQRResponse({
    required this.status,
    required this.message,
    required this.marketingPartnerId,
    required this.marketingPartner,
    this.upiId,
    required this.amount,
    required this.qrImage,
    required this.upiLink,
    required this.paymentMethod,
    this.bankDetails,
    this.chequeUploadUrl,
  });

  factory PaymentQRResponse.fromJson(Map<String, dynamic> json) {
    return PaymentQRResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      marketingPartnerId: json['marketing_partner_id'] ?? 0,
      marketingPartner: json['marketing_partner'] ?? '',
      upiId: json['upi_id'],
      amount: json['amount']?.toString() ?? '0',
      qrImage: json['qr_image'] ?? '',
      upiLink: json['upi_link'] ?? '',
      paymentMethod: json['payment_method'] ?? 'upi',
      bankDetails: json['bank_details'] != null
          ? BankDetails.fromJson(json['bank_details'])
          : null,
      chequeUploadUrl: json['cheque_upload_url'],
    );
  }

  double get amountDouble => double.tryParse(amount) ?? 0.0;
}

class BankDetails {
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;

  BankDetails({
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'] ?? '',
    );
  }
}