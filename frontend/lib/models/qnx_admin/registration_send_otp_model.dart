class SendOtpModel {
  final String email;

  SendOtpModel({required this.email});

  Map<String, dynamic> toJson() => {
    "email": email,
  };
}



class VerifyOtpModel {
  final String email;
  final String otp;

  VerifyOtpModel({required this.email, required this.otp});

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp};
  }
}