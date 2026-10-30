class PackingMaterialEnquiryResponse {
  final bool success;
  final String message;
  final int count;
  final List<PackingMaterialEnquiry> data;

  PackingMaterialEnquiryResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PackingMaterialEnquiryResponse.fromJson(Map<String, dynamic> json) {
    return PackingMaterialEnquiryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PackingMaterialEnquiry.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class PackingMaterialEnquiry {
  final int enquiryId;
  final String enquiryNumber;
  final int companyId;
  final String companyName;
  final int customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String description;
  final String status;
  final List<PackingMaterialItem> items;
  final String createdAt;
  final String updatedAt;

  PackingMaterialEnquiry({
    required this.enquiryId,
    required this.enquiryNumber,
    required this.companyId,
    required this.companyName,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.description,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PackingMaterialEnquiry.fromJson(Map<String, dynamic> json) {
    return PackingMaterialEnquiry(
      enquiryId: json['enquiry_id'] ?? 0,
      enquiryNumber: json['enquiry_number'] ?? '',
      companyId: json['company_id'] ?? 0,
      companyName: json['company_name'] ?? '',
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PackingMaterialItem.fromJson(e))
          .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}/"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return createdAt;
    }
  }

  int get totalItems => items.length;
}

class PackingMaterialItem {
  final int id;
  final String materialName;
  final double quantity;
  final String unit;
  final String? size;
  final String? description;

  PackingMaterialItem({
    required this.id,
    required this.materialName,
    required this.quantity,
    required this.unit,
    this.size,
    this.description,
  });

  factory PackingMaterialItem.fromJson(Map<String, dynamic> json) {
    return PackingMaterialItem(
      id: json['id'] ?? 0,
      materialName: json['material_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      size: json['size'],
      description: json['description'],
    );
  }

  String get quantityText {
    // Remove .0 if integer
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }
}