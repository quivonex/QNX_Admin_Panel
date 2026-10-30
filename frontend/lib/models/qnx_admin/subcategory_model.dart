class SubCategoryModel {

  final int id;
  final String name;
  final String description;
  final bool isActive;
  final String createdAt;
  final int? user;
  final int category;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.user,
    required this.category,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {

    return SubCategoryModel(

      id: json["id"],
      name: json["name"],
      description: json["description"] ?? "",
      isActive: json["is_active"],
      createdAt: json["created_at"],
      user: json["user"],
      category: json["category"],

    );
  }
}