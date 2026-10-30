class Category {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;

  Category({
    this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "description": description,
      "status": isActive,
    };
  }
}


class CategoryUpdateModel {

  final int id;
  final String name;
  final String description;

  CategoryUpdateModel({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
    };
  }
}


class CategoryDeleteModel {

  final int id;

  CategoryDeleteModel({
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
    };
  }
}

/*
class CategoryAllModel {

  final int id;
  final String name;
  final String description;
  final bool isActive;
  final int? user;

  CategoryAllModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.user,
  });

  factory CategoryAllModel.fromJson(Map<String, dynamic> json) {

    return CategoryAllModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
      user: json['user'],
    );

  }
}*/

class CategoryAllModel {

  final int id;
  final String name;
  final String description;
  final bool isActive;
  final int? user;

  CategoryAllModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.user,
  });

  factory CategoryAllModel.fromJson(Map<String, dynamic> json) {

    return CategoryAllModel(

      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      isActive: json['is_active'] ?? false,
      user: json['user'],

    );
  }
}