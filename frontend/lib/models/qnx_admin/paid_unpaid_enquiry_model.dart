class PaidUnpaidEnquiryResponse {
  final bool status;
  final PaidUnpaidEnquiryData data;

  PaidUnpaidEnquiryResponse({
    required this.status,
    required this.data,
  });

  factory PaidUnpaidEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return PaidUnpaidEnquiryResponse(
      status: json['status'] ?? false,
      data: PaidUnpaidEnquiryData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaidUnpaidEnquiryData {
  final int totalEnquiries;
  final int paidEnquiries;
  final int unpaidEnquiries;

  PaidUnpaidEnquiryData({
    required this.totalEnquiries,
    required this.paidEnquiries,
    required this.unpaidEnquiries,
  });

  factory PaidUnpaidEnquiryData.fromJson(Map<String, dynamic> json) {
    return PaidUnpaidEnquiryData(
      totalEnquiries: json['total_enquiries'] ?? 0,
      paidEnquiries: json['paid_enquiries'] ?? 0,
      unpaidEnquiries: json['unpaid_enquiries'] ?? 0,
    );
  }
}