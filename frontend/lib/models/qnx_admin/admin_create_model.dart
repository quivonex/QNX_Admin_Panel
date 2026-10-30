class RegisterModel {
  final String username;
  final String email;
  final String password;
  final String name;
  final String role;
  final String phoneNumber;

  RegisterModel({
    required this.username,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'phone_number': phoneNumber,
    };
  }
}





