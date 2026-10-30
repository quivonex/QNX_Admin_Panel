class CompleteEnquiryResponse {
  final bool status;
  final CompleteEnquiryData data;

  CompleteEnquiryResponse({
    required this.status,
    required this.data,
  });

  factory CompleteEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return CompleteEnquiryResponse(
      status: json['status'] ?? false,
      data: CompleteEnquiryData.fromJson(json['data'] ?? {}),
    );
  }
}

class CompleteEnquiryData {
  final int totalEnquiries;
  final int completeEnquiries;
  final int incompleteEnquiries;

  CompleteEnquiryData({
    required this.totalEnquiries,
    required this.completeEnquiries,
    required this.incompleteEnquiries,
  });

  factory CompleteEnquiryData.fromJson(Map<String, dynamic> json) {
    return CompleteEnquiryData(
      totalEnquiries: json['total_enquiries'] ?? 0,
      completeEnquiries: json['complete_enquiries'] ?? 0,
      incompleteEnquiries: json['incomplete_enquiries'] ?? 0,
    );
  }
}