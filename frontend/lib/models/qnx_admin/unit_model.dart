class Unit {

  final int? id;
  final String name;
  final String shortName;

  Unit({
    this.id,
    required this.name,
    required this.shortName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "short_name": shortName,
    };
  }
}


class UnitUpdateModel {

  final int id;
  final String unitName;
  final String unitCode;
  final String description;

  UnitUpdateModel({
    required this.id,
    required this.unitName,
    required this.unitCode,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "unit_name": unitName,
      "unit_code": unitCode,
      "description": description,
    };
  }
}