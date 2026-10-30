class Product {
  final int? id;
  final int? category;
  final int? brand;
  final int? unit;

  final String? categoryName;
  final String? brandName;
  final String? unitName;

  final String name;
  final String slug;
  final String description;
  final String price;
  final String? discountPrice;

  final int? stockQuantity;

  final String? productCode;
  final String? sku;

  final String? voltage;
  final String? power;
  final String? weight;
  final String? dimensions;

  final String? thumbnailS3Key;

  final bool? isActive;
  final bool? isFeatured;

  final String? createdAt;

  final List<ProductImage> images;

  Product({
    this.id,
    this.category,
    this.brand,
    this.unit,
    this.categoryName,
    this.brandName,
    this.unitName,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    this.discountPrice,
    this.stockQuantity,
    this.productCode,
    this.sku,
    this.voltage,
    this.power,
    this.weight,
    this.dimensions,
    this.thumbnailS3Key,
    this.isActive,
    this.isFeatured,
    this.createdAt,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      category: json['category'],
      brand: json['brand'],
      unit: json['unit'],

      // Name fields (API sometimes nested so safe parsing)
      categoryName: json['category_name'] ?? json['categoryName'],
      brandName: json['brand_name'] ?? json['brandName'],
      unitName: json['unit_name'] ?? json['unitName'],

      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      discountPrice: json['discount_price']?.toString(),

      stockQuantity: json['stock_quantity'],

      productCode: json['product_code'],
      sku: json['sku'],

      voltage: json['voltage'],
      power: json['power'],
      weight: json['weight'],
      dimensions: json['dimensions'],

      thumbnailS3Key: json['thumbnail_s3_key'],

      isActive: json['is_active'],
      isFeatured: json['is_featured'],

      createdAt: json['created_at'],

      images: (json['images'] as List?)
          ?.map((img) => ProductImage.fromJson(img))
          .toList() ??
          [],
    );
  }




  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'brand': brand,
      'unit': unit,
      'name': name,
      'slug': slug,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'stock_quantity': stockQuantity,
      'product_code': productCode,
      'sku': sku,
      'voltage': voltage,
      'power': power,
      'weight': weight,
      'dimensions': dimensions,
    };
  }
}

class ProductImage {
  final int? id;
  final String imageS3Key;
  final String? createdAt;

  ProductImage({
    this.id,
    required this.imageS3Key,
    this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      imageS3Key: json['image_s3_key'] ?? '',
      createdAt: json['created_at'],
    );
  }
}





// models/product_model.dart

class PendingProductImage {
  final int id;
  final String image;
  final String createdAt;
  // Optional variant fields (from API response)
  final int? imageIndex;
  final String? variantPrice;
  final int? variantStock;
  final String? variantSku;
  final Map<String, dynamic>? variantAttributes;

  PendingProductImage({
    required this.id,
    required this.image,
    required this.createdAt,
    this.imageIndex,
    this.variantPrice,
    this.variantStock,
    this.variantSku,
    this.variantAttributes,
  });

  factory PendingProductImage.fromJson(Map<String, dynamic> json) {
    return PendingProductImage(
      id: json["id"] ?? 0,
      image: json["image_s3_key"] ?? json["image"] ?? "",
      createdAt: json["created_at"] ?? "",
      imageIndex: json["image_index"],
      variantPrice: json["price"]?.toString(),
      variantStock: json["stock_quantity"],
      variantSku: json["sku"],
      variantAttributes: json["attributes"] is Map
          ? Map<String, dynamic>.from(json["attributes"])
          : null,
    );
  }
}

class PendingProductSpecification {
  final String key;
  final String value;

  PendingProductSpecification({
    required this.key,
    required this.value,
  });

  factory PendingProductSpecification.fromJson(Map<String, dynamic> json) {
    return PendingProductSpecification(
      key: json["key"] ?? "",
      value: json["value"] ?? "",
    );
  }
}

class PendingProductModel {
  final int id;
  final String name;
  final String description;
  final String price;
  final String discountType;
  final String discountValue;
  final String finalPrice;
  final int stockQuantity;
  final String productCode;
  final String sku;
  final String weight;
  final String length;
  final String width;
  final String height;
  final String manufacturingDate;
  final String? expiryDate;
  final String bestBeforeDuration;
  final String hsnCode;
  final Map<String, dynamic>? attributes;
  final List<PendingProductSpecification> specifications;
  final bool? franchiseAvailable;
  final String categoryName;
  final String subcategoryName;
  final String brandName;
  final String unitName;
  final String companyName;

  final String thumbnail;
  final String status;
  final bool isActive;
  final bool isFeatured;
  final String createdAt;

  final int company;
  final int category;
  final int subcategory;
  final int brand;
  final int unit;


  final List<PendingProductImage> images;
  final List<PendingProductVariant> variants;
  final List<String> videos;
  PendingProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountType,
    required this.discountValue,
    required this.finalPrice,
    required this.stockQuantity,
    required this.productCode,
    required this.sku,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.bestBeforeDuration,
    required this.hsnCode,
    required this.attributes,
    required this.specifications,
    required this.categoryName,
    required this.subcategoryName,
    required this.brandName,
    required this.unitName,
    required this.companyName,
    required this.thumbnail,
    required this.status,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.company,
    required this.category,
    required this.subcategory,
    required this.brand,
    required this.unit,
    required this.images,
    required this.variants,
    required this.videos,
    required this.franchiseAvailable,
  });

  factory PendingProductModel.fromJson(Map<String, dynamic> json) {
    List imagesList = json["images"] ?? [];
    List<PendingProductSpecification> specs = [];

    var specsData = json["specifications"];
    if (specsData is List) {
      specs = specsData.map((e) => PendingProductSpecification.fromJson(e)).toList();
    } else if (specsData is Map) {
      specs = specsData.entries
          .map((e) => PendingProductSpecification(key: e.key, value: e.value.toString()))
          .toList();
    }

    Map<String, dynamic>? attrs;
    if (json["attributes"] != null && json["attributes"] is Map) {
      attrs = Map<String, dynamic>.from(json["attributes"]);
    }

    return PendingProductModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      price: json["price"]?.toString() ?? "0",
      discountType: json["discount_type"]?.toString() ?? "",
      discountValue: json["discount_value"]?.toString() ?? "",
      finalPrice: json["final_price"]?.toString() ?? "0",
      stockQuantity: json["stock_quantity"] ?? 0,
      productCode: json["product_code"] ?? "",
      sku: json["sku"] ?? "",
      weight: json["weight"]?.toString() ?? "",
      length: json["length"]?.toString() ?? "",
      width: json["width"]?.toString() ?? "",
      height: json["height"]?.toString() ?? "",
      manufacturingDate: json["manufacturing_date"] ?? "",
      expiryDate: json["expiry_date"],
      bestBeforeDuration: json["best_before_duration"]?.toString() ?? "",
      hsnCode: json["HSN_code"] ?? "",
      attributes: attrs,
      specifications: specs,
      categoryName: json["category_name"] ?? "",
      subcategoryName: json["subcategory_name"] ?? "",
      brandName: json["brand_name"] ?? "",
      unitName: json["unit_name"] ?? "",
      companyName: json["company_name"] ?? "",
      thumbnail: json["thumbnail_s3_key"] ?? "",
      status: json["status"] ?? "",
      isActive: json["is_active"] ?? false,
      isFeatured: json["is_featured"] ?? false,
      createdAt: json["created_at"] ?? "",
      company: json["company"] ?? 0,
      category: json["category"] ?? 0,
      subcategory: json["subcategory"] ?? 0,
      franchiseAvailable: json["is_franchise_available"] ?? false,
      brand: json["brand"] ?? 0,
      unit: json["unit"] ?? 0,
      images: imagesList.map((e) => PendingProductImage.fromJson(e)).toList(),
      variants: (json["variants"] as List?)
          ?.map((e) => PendingProductVariant.fromJson(e))
          .toList() ?? [],
      videos: (json["videos"] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}


class ProductApproveModel {

  final int productId;

  ProductApproveModel({
    required this.productId,
  });

  Map<String, dynamic> toJson() {

    return {
      "product_id": productId
    };

  }

}


class ApprovedProductImage {
  final int id;
  final String image;
  final String createdAt;

  ApprovedProductImage({
    required this.id,
    required this.image,
    required this.createdAt,
  });

  factory ApprovedProductImage.fromJson(Map<String, dynamic> json) {
    return ApprovedProductImage(
      id: json["id"] ?? 0,
      image: json["image_s3_key"] ?? "",
      createdAt: json["created_at"] ?? "",
    );
  }
}

class ApprovedProductSpecification {
  final String key;
  final String value;

  ApprovedProductSpecification({
    required this.key,
    required this.value,
  });

  factory ApprovedProductSpecification.fromJson(Map<String, dynamic> json) {
    return ApprovedProductSpecification(
      key: json["key"] ?? "",
      value: json["value"] ?? "",
    );
  }
}

class ApprovedProductModel {
  final int id;
  final String name;
  final String description;
  final String price;
  final String? discountType;
  final String discountValue;
  final String finalPrice;
  final int stockQuantity;
  final String productCode;
  final String sku;
  final String weight;
  final String length;
  final String width;
  final String height;
  final String manufacturingDate;
  final String? expiryDate;
  final String bestBeforeDuration;
  final String hsnCode;
  final Map<String, dynamic>? attributes;
  final List<ApprovedProductSpecification> specifications;
  final String categoryName;
  final String subcategoryName;
  final String brandName;
  final String unitName;
  final String companyName;
  final bool? franchiseAvailable;  // ✅ हे फील्ड आहे
  final String thumbnail;
  final String status;
  final bool isActive;
  final bool isFeatured;
  final String createdAt;
  final int company;
  final int category;
  final int subcategory;
  final int brand;
  final int unit;
  final List<PendingProductVariant> variants;
  final List<String> videos;
  final List<ApprovedProductImage> images;

  ApprovedProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountType,
    required this.discountValue,
    required this.finalPrice,
    required this.stockQuantity,
    required this.productCode,
    required this.sku,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.bestBeforeDuration,
    required this.hsnCode,
    required this.attributes,
    required this.specifications,
    required this.categoryName,
    required this.subcategoryName,
    required this.brandName,
    required this.unitName,
    required this.companyName,
    required this.thumbnail,
    required this.status,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.company,
    required this.category,
    required this.subcategory,
    required this.brand,
    required this.unit,
    required this.images,
    required this.variants,
    required this.videos,
    this.franchiseAvailable,  // ✅ nullable
  });

  factory ApprovedProductModel.fromJson(Map<String, dynamic> json) {
    // ... existing parsing code ...

    return ApprovedProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      discountType: json['discount_type']?.toString(),
      discountValue: json['discount_value']?.toString() ?? '',
      finalPrice: json['final_price']?.toString() ?? '0',
      stockQuantity: json['stock_quantity'] ?? 0,
      productCode: json['product_code'] ?? '',
      sku: json['sku'] ?? '',
      weight: json['weight']?.toString() ?? '',
      length: json['length']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      manufacturingDate: json['manufacturing_date'] ?? '',
      expiryDate: json['expiry_date']?.toString(),
      bestBeforeDuration: json['best_before_duration']?.toString() ?? '',
      hsnCode: json['HSN_code'] ?? '',
      attributes: json['attributes'] is Map ? Map<String, dynamic>.from(json['attributes']) : null,
      specifications: (json['specifications'] as List?)?.map((e) => ApprovedProductSpecification.fromJson(e)).toList() ?? [],
      categoryName: json['category_name'] ?? '',
      subcategoryName: json['subcategory_name'] ?? '',
      brandName: json['brand_name'] ?? '',
      unitName: json['unit_name'] ?? '',
      companyName: json['company_name'] ?? '',
      thumbnail: json['thumbnail_s3_key'] ?? '',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      createdAt: json['created_at'] ?? '',
      company: json['company'] ?? 0,
      category: json['category'] ?? 0,
      subcategory: json['subcategory'] ?? 0,
      brand: json['brand'] ?? 0,
      unit: json['unit'] ?? 0,
      images: (json['images'] as List?)?.map((e) => ApprovedProductImage.fromJson(e)).toList() ?? [],
      variants: (json['variants'] as List?)?.map((e) => PendingProductVariant.fromJson(e)).toList() ?? [],
      videos: (json['videos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      franchiseAvailable: json['is_franchise_available'] ?? false,  // ✅ ही critical लाइन
    );
  }
}

class RejectProductModel {

  final int productId;
  final String rejectReason;

  RejectProductModel({
    required this.productId,
    required this.rejectReason,
  });

  Map<String, dynamic> toJson() {

    return {
      "product_id": productId,
      "reject_reason": rejectReason
    };

  }

}









class LatestProductResponse {
  final bool status;
  final String message;
  final List<LatestProduct> data;

  LatestProductResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LatestProductResponse.fromJson(Map<String, dynamic> json) {
    return LatestProductResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((item) => LatestProduct.fromJson(item))
          .toList(),
    );
  }
}

class LatestProduct {
  final int id;
  final String thumbnail;
  final String name;
  final String companyName;
  final String categoryName;
  final String brandName;

  LatestProduct({
    required this.id,
    required this.thumbnail,
    required this.name,
    required this.companyName,
    required this.categoryName,
    required this.brandName,
  });

  factory LatestProduct.fromJson(Map<String, dynamic> json) {
    return LatestProduct(
      id: json['id'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      brandName: json['brand_name'] ?? '',
    );
  }
}






class ProductCountModel {
  final bool status;
  final int approvedProductCount;

  ProductCountModel({
    required this.status,
    required this.approvedProductCount,
  });

  factory ProductCountModel.fromJson(Map<String, dynamic> json) {
    return ProductCountModel(
      status: json['status'] ?? false,
      approvedProductCount: json['approved_product_count'] ?? 0,
    );
  }
}



class PendingProductVariant {
  final int id;
  final Map<String, dynamic> attributes;
  final String price;
  final int stockQuantity;
  final String sku;
  final int? imageIndex;
  final String? image;

  PendingProductVariant({
    required this.id,
    required this.attributes,
    required this.price,
    required this.stockQuantity,
    required this.sku,
    this.imageIndex,
    this.image,
  });

  factory PendingProductVariant.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> attributes = {};
    if (json["attributes"] != null && json["attributes"] is Map) {
      attributes = Map<String, dynamic>.from(json["attributes"]);
    }

    return PendingProductVariant(
      id: json["id"] ?? 0,
      attributes: attributes,
      price: json["price"]?.toString() ?? "0",
      stockQuantity: json["stock_quantity"] ?? 0,
      sku: json["sku"] ?? "",
      imageIndex: json["image_index"],
      image: json["image"]?.toString(),
    );
  }
}