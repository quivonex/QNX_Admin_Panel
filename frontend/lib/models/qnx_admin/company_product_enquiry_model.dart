class PendingEnquiry {
  final int id;
  final String productName;
  final String? productImage;
  final List<dynamic>? variants;
  final String? companyName;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedVariant;
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
  final String status;
  final String createdAt;
  final int product;
  final bool isPaid;
  final String? razorpayPaymentId;
  final String? enquiryReferralCode; // ✅ NEW FIELD

  PendingEnquiry({
    required this.id,
    required this.productName,
    this.productImage,
    this.companyName,
    this.variants,
    this.selectedColor,
    this.selectedSize,
    this.selectedVariant,
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
    required this.status,
    required this.createdAt,
    required this.product,
    required this.isPaid,
    this.razorpayPaymentId,
    this.enquiryReferralCode, // ✅ NEW
  });

  factory PendingEnquiry.fromJson(Map<String, dynamic> json) {
    return PendingEnquiry(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      variants: json['variants'] as List<dynamic>?,
      companyName: json['company_name'],
      selectedColor: json['selected_color'],
      selectedSize: json['selected_size'],
      selectedVariant: json['selected_variant'],
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
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      product: json['product'] ?? 0,
      isPaid: json['is_paid'] ?? false,
      razorpayPaymentId: json['razorpay_payment_id'],
      enquiryReferralCode: json['enquiry_referral_code'], // ✅ NEW
    );
  }

  // ✅ COPYWITH METHOD मध्ये enquiryReferralCode add करा
  PendingEnquiry copyWith({
    int? id,
    String? productName,
    String? productImage,
    List<dynamic>? variants,
    String? companyName,
    String? selectedColor,
    String? selectedSize,
    String? selectedVariant,
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
    String? status,
    String? createdAt,
    int? product,
    bool? isPaid,
    String? razorpayPaymentId,
    String? enquiryReferralCode, // ✅ NEW
  }) {
    return PendingEnquiry(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      variants: variants ?? this.variants,
      companyName: companyName ?? this.companyName,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedVariant: selectedVariant ?? this.selectedVariant,
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
      isPaid: isPaid ?? this.isPaid,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      enquiryReferralCode: enquiryReferralCode ?? this.enquiryReferralCode, // ✅ NEW
    );
  }
}