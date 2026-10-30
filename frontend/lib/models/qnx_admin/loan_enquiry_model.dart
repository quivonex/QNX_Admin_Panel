// ============================================================
// REQUEST MODEL
// ============================================================
import 'package:flutter/material.dart';

class LoanEnquiryListRequest {
  final int? page;
  final int? limit;
  final String? search;
  final String? status;
  final String? loanType;
  final String? fromDate;
  final String? toDate;

  LoanEnquiryListRequest({
    this.page,
    this.limit,
    this.search,
    this.status,
    this.loanType,
    this.fromDate,
    this.toDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (loanType != null && loanType!.isNotEmpty) 'loan_type': loanType,
      if (fromDate != null && fromDate!.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate!.isNotEmpty) 'to_date': toDate,
    };
  }
}

// ============================================================
// RESPONSE MODEL
// ============================================================
class LoanEnquiryListResponse {
  final bool success;
  final String message;
  final int count;
  final List<LoanEnquiry> data;

  LoanEnquiryListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory LoanEnquiryListResponse.fromJson(Map<String, dynamic> json) {
    return LoanEnquiryListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: (json['data'] as List? ?? [])
          .map((e) => LoanEnquiry.fromJson(e))
          .toList(),
    );
  }
}

// ============================================================
// LOAN ENQUIRY MODEL
// ============================================================
class LoanEnquiry {
  final int id;
  final String name;
  final String mobile;
  final String email;
  final String loanType;
  final String loanAmount;
  final int tenureYears;
  final String monthlyIncome;
  final String city;
  final String state;
  final String pincode;
  final String status;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanEnquiry({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.loanType,
    required this.loanAmount,
    required this.tenureYears,
    required this.monthlyIncome,
    required this.city,
    required this.state,
    required this.pincode,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanEnquiry.fromJson(Map<String, dynamic> json) {
    return LoanEnquiry(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      loanType: json['loan_type'] ?? '',
      loanAmount: json['loan_amount']?.toString() ?? '0',
      tenureYears: json['tenure_years'] ?? 0,
      monthlyIncome: json['monthly_income']?.toString() ?? '0',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper methods for display
  String get formattedLoanAmount => '₹${double.tryParse(loanAmount)?.toStringAsFixed(0) ?? loanAmount}';
  String get formattedMonthlyIncome => '₹${double.tryParse(monthlyIncome)?.toStringAsFixed(0) ?? monthlyIncome}';
  String get formattedCreatedAt => '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  String get formattedUpdatedAt => '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';

  String get loanTypeDisplay {
    switch (loanType) {
      case 'home_loan': return 'Home Loan';
      case 'car_loan': return 'Car Loan';
      case 'personal_loan': return 'Personal Loan';
      case 'business_loan': return 'Business Loan';
      case 'education_loan': return 'Education Loan';
      default: return loanType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'new': return 'New';
      case 'in_progress': return 'In Progress';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'completed': return 'Completed';
      default: return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case 'new': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.purple;
      default: return Colors.grey;
    }
  }
}