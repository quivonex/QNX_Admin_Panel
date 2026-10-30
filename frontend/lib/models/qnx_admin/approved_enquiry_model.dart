import 'package:json_annotation/json_annotation.dart';


class ApprovedEnquiry {
  final int id;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedVariant;
  final String? productName;
  final String? companyName;
  final String? productImage;
  final List<dynamic>? variants;
  final String? personName;
  final String? email;
  final String? contact;
  final String? pincode;
  final String? address;
  final String? message;
  final String? demoRequired;
  final String? demoType;
  final dynamic attachment;
  final bool isSentToCompany;
  final bool isComplete;
  final bool isDispatched;
  final bool isDelivered;
  final String status;
  final String createdAt;
  final int product;
  final bool isPaid;
  final String? razorpayPaymentId;
  final String? enquiryReferralCode; // ✅ NEW FIELD

  String get deliveryStatus {
    if (isComplete) return 'Complete';
    if (isDelivered) return 'Delivered';
    if (isDispatched) return 'Dispatched';
    return 'Pending';
  }

  ApprovedEnquiry({
    required this.id,
    this.selectedColor,
    this.selectedSize,
    this.selectedVariant,
    this.productName,
    this.companyName,
    this.productImage,
    this.variants,
    this.personName,
    this.email,
    this.contact,
    this.pincode,
    this.address,
    this.message,
    this.demoRequired,
    this.demoType,
    this.attachment,
    required this.isSentToCompany,
    required this.isComplete,
    required this.isDispatched,
    required this.isDelivered,
    required this.status,
    required this.createdAt,
    required this.product,
    required this.isPaid,
    this.razorpayPaymentId,
    this.enquiryReferralCode, // ✅ NEW
  });

  factory ApprovedEnquiry.fromJson(Map<String, dynamic> json) {
    return ApprovedEnquiry(
      id: json['id'] ?? 0,
      selectedColor: json['selected_color'],
      selectedSize: json['selected_size'],
      selectedVariant: json['selected_variant'],
      productName: json['product_name'],
      companyName: json['company_name'],
      productImage: json['product_image'],
      variants: json['variants'] as List<dynamic>?,
      personName: json['person_name'],
      email: json['email'],
      contact: json['contact'],
      pincode: json['pincode'],
      address: json['address'],
      message: json['message'],
      demoRequired: json['demo_required'],
      demoType: json['demo_type'],
      attachment: json['attachment'],
      isSentToCompany: json['is_sent_to_company'] ?? false,
      isComplete: json['is_complete'] ?? false,
      isDispatched: json['is_dispatched'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      product: json['product'] ?? 0,
      isPaid: json['is_paid'] ?? false,
      razorpayPaymentId: json['razorpay_payment_id'],
      enquiryReferralCode: json['enquiry_referral_code'], // ✅ NEW
    );
  }

  // ✅ COPYWITH METHOD
  ApprovedEnquiry copyWith({
    int? id,
    String? selectedColor,
    String? selectedSize,
    String? selectedVariant,
    String? productName,
    String? companyName,
    String? productImage,
    List<dynamic>? variants,
    String? personName,
    String? email,
    String? contact,
    String? pincode,
    String? address,
    String? message,
    String? demoRequired,
    String? demoType,
    dynamic attachment,
    bool? isSentToCompany,
    bool? isComplete,
    bool? isDispatched,
    bool? isDelivered,
    String? status,
    String? createdAt,
    int? product,
    bool? isPaid,
    String? razorpayPaymentId,
    String? enquiryReferralCode, // ✅ NEW
  }) {
    return ApprovedEnquiry(
      id: id ?? this.id,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      productImage: productImage ?? this.productImage,
      variants: variants ?? this.variants,
      personName: personName ?? this.personName,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      pincode: pincode ?? this.pincode,
      address: address ?? this.address,
      message: message ?? this.message,
      demoRequired: demoRequired ?? this.demoRequired,
      demoType: demoType ?? this.demoType,
      attachment: attachment ?? this.attachment,
      isSentToCompany: isSentToCompany ?? this.isSentToCompany,
      isComplete: isComplete ?? this.isComplete,
      isDispatched: isDispatched ?? this.isDispatched,
      isDelivered: isDelivered ?? this.isDelivered,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
      isPaid: isPaid ?? this.isPaid,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      enquiryReferralCode: enquiryReferralCode ?? this.enquiryReferralCode, // ✅ NEW
    );
  }
}





class ApprovedEnquiryResponse {
  final bool status;
  final List<ApprovedEnquiry> data;

  ApprovedEnquiryResponse({
    required this.status,
    required this.data,
  });

  factory ApprovedEnquiryResponse.fromJson(Map<String, dynamic> json) {
    final List list = json['data'] ?? [];
    return ApprovedEnquiryResponse(
      status: json['status'] ?? false,
      data: list.map((e) => ApprovedEnquiry.fromJson(e)).toList(),
    );
  }
}