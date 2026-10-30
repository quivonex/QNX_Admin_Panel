class OfferModel {
  final int id;
  final String title;
  final String description;
  final String? offerType;
  final String? discountValue;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;
  final List<ProductDetail> productDetails;
  final List<String>? branchNames;
  final int? companyId;
  final List<int> products;
  final List<int> branches;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    this.offerType,
    this.discountValue,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    this.productDetails = const [],
    this.branchNames,
    this.companyId,
    this.products = const [],
    this.branches = const [],
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      offerType: json['offer_type'],
      discountValue: json['discount_value']?.toString(),
      startDate: json['start_date'],
      endDate: json['end_date'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      productDetails: (json['product_details'] as List?)
          ?.map((e) => ProductDetail.fromJson(e))
          .toList() ??
          [],
      branchNames: (json['branch_names'] as List?)?.cast<String>(),
      companyId: json['company'],
      products: (json['products'] as List?)?.cast<int>() ?? [],
      branches: (json['branch'] as List?)?.cast<int>() ?? [],
    );
  }
}

class ProductDetail {
  final String productName;
  final String company;

  ProductDetail({required this.productName, required this.company});

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      productName: json['product_name'] ?? '',
      company: json['company'] ?? '',
    );
  }
}

class OfferUpdateModel {

  int id;
  String title;
  String description;
  String offerType;
  int discountValue;
  String startDate;
  String endDate;

  OfferUpdateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.offerType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {

    return {
      "id": id,
      "title": title,
      "description": description,
      "offer_type": offerType,
      "discount_value": discountValue,
      "start_date": startDate,
      "end_date": endDate,
    };

  }

}



class SingleOfferModel {

  int? id;
  String? title;
  String? description;
  String? offerType;
  String? discountValue;
  String? startDate;
  String? endDate;
  bool? isActive;
  String? createdAt;

  SingleOfferModel({
    this.id,
    this.title,
    this.description,
    this.offerType,
    this.discountValue,
    this.startDate,
    this.endDate,
    this.isActive,
    this.createdAt,
  });

  factory SingleOfferModel.fromJson(Map<String, dynamic> json) {

    return SingleOfferModel(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      offerType: json["offer_type"],
      discountValue: json["discount_value"],
      startDate: json["start_date"],
      endDate: json["end_date"],
      isActive: json["is_active"],
      createdAt: json["created_at"],
    );

  }

}