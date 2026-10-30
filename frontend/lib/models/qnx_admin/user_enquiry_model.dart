class UserEnquiry {

  final int id;
  final String name;
  final String email;
  final String phone;
  final String product;
  final String address;
  final String message;
  final String createdAt;

  UserEnquiry({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.product,
    required this.address,
    required this.message,
    required this.createdAt,
  });

  factory UserEnquiry.fromJson(Map<String, dynamic> json) {

    return UserEnquiry(

      id: json["id"],
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      product: json["product"] ?? "",
      address: json["address"] ?? "",
      message: json["message"] ?? "",
      createdAt: json["created_at"] ?? "",

    );
  }
}