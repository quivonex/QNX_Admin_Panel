class Role {
  final int? id;
  final String roleName;
  final String description;
  final bool isActive;
  final String? createdAt;

  Role({
    this.id,
    required this.roleName,
    required this.description,
    required this.isActive,
    this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      roleName: json['role_name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "role_name": roleName,
      "description": description,
      "is_active": isActive,
    };
  }
}

class RoleUpdateModel {

  final int id;
  final String roleName;
  final String description;

  RoleUpdateModel({
    required this.id,
    required this.roleName,
    required this.description,
  });

  Map<String, dynamic> toJson() {

    return {
      "id": id,
      "role_name": roleName,
      "description": description,
    };

  }
}

class RoleDeleteModel {

  final int id;

  RoleDeleteModel({
    required this.id,
  });

  Map<String, dynamic> toJson() {

    return {
      "id": id,
    };

  }

}

class RoleDetailModel {

  final int id;
  final String roleName;
  final String description;
  final bool isActive;
  final String createdAt;

  RoleDetailModel({
    required this.id,
    required this.roleName,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory RoleDetailModel.fromJson(Map<String, dynamic> json) {

    return RoleDetailModel(
      id: json['id'],
      roleName: json['role_name'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
    );

  }

}