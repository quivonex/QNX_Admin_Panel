class LoginModel {
  final String username;
  final String password;
  final String role;
  final String? fcmToken; // ✅ Add this field

  LoginModel({
    required this.username,
    required this.password,
    required this.role,
    this.fcmToken, // ✅ Optional parameter
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "role": role,
      if (fcmToken != null && fcmToken!.isNotEmpty)
        "fcm_token": fcmToken, // ✅ Only add if not null/empty
    };
  }
}

class SendOtpModel {

  final String email;

  SendOtpModel({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
    };
  }
}

class VerifyOtpModel {

  final String email;
  final String otp;

  VerifyOtpModel({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {

    return {
      "email": email,
      "otp": otp,
    };
  }
}

class ResetPasswordModel {

  final String email;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordModel({
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "new_password": newPassword,
      "confirm_password": confirmPassword,
    };
  }
}