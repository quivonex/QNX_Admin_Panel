// TODO Implement this library.
class RetrieveBankDetailsResponse {
  final String? status;
  final dynamic data;
  final String? message;

  RetrieveBankDetailsResponse({
    this.status,
    this.data,
    this.message,
  });

  factory RetrieveBankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return RetrieveBankDetailsResponse(
      status: json['status'],
      data: json['data'],
      message: json['message'],
    );
  }
}