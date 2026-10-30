// lib/models/user_model.dart
class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final bool isActive;
  final String? role;
  final List<CompanySimple>? companies;   // NEW: list of companies

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.isActive,
    this.role,
    this.companies,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<CompanySimple>? companyList;
    if (json['companies'] != null && json['companies'] is List) {
      companyList = (json['companies'] as List)
          .map((c) => CompanySimple.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      isActive: json['is_active'] ?? false,
      role: json['role'],
      companies: companyList,
    );
  }

  // Optional: toJson() if needed for sending data back
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'is_active': isActive,
      'role': role,
      'companies': companies?.map((c) => c.toJson()).toList(),
    };
  }
}

// Simple company model (only fields returned by the API)
class CompanySimple {
  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isActive;

  CompanySimple({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
  });

  factory CompanySimple.fromJson(Map<String, dynamic> json) {
    return CompanySimple(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'is_active': isActive,
    };
  }
}