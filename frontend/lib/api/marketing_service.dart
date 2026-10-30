// lib/services/marketing_profile_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_url.dart';
import '../api/api_response.dart';
import '../models/marketing_partner/property_referral_model.dart';
import '../models/qnx_admin/bank_details_request.dart' hide RetrieveBankDetailsResponse;
import '../models/qnx_admin/marketing_head_model.dart';
import '../models/marketing_head/marketing_profile_model.dart';
import '../models/marketing_head/my_team_model.dart';
import '../models/marketing_head/partner_company_model.dart';
import '../../models/qnx_admin/referral_partner_model.dart';
import '../../models/marketing_head/referred_companies_model.dart';
import '../models/marketing_partner/commission_model.dart';
// Marketing Partner Models
import '../../models/marketing_partner/my_referred_companies_model.dart';
// ✅ FIXED: Correct import for product_referral_model
import '../../models/marketing_partner/product_refral_model.dart';
import '../models/marketing_partner/franchise_referral_model.dart';
import '../models/marketing_partner/pending_commission_model.dart';
import '../models/marketing_partner/wallet_model.dart';
import '../models/qnx_admin/partner_commission_list_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_url.dart';
import '../models/marketing_partner/update_bank_details_model.dart';
import '../models/marketing_partner/property_model.dart';


// ----------------------------------------------------------------------
// Marketing Profile Service (existing)
// ----------------------------------------------------------------------
// lib/services/marketing_profile_service.dart
class MarketingProfileService {
  Future<MarketingProfileResponse> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.myMarketingProfile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📤 Get My Profile');
    print('📥 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return MarketingProfileResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }
}
// ----------------------------------------------------------------------
// Referral Partner Service (extended with approve/reject methods)
// ----------------------------------------------------------------------
class ReferralPartnerService {
  Future<MyReferredPartnerResponse> getMyReferredPartners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.myReferredPartners),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MyReferredPartnerResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load referred partners: ${response.statusCode}');
    }
  }

  Future<List<PartnerCompany>> getPartnerCompanies(int partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.partnerCompanies),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'partner_id': partnerId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'] ?? [];
      return data.map((e) => PartnerCompany.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load partner companies: ${response.statusCode}');
    }
  }

  Future<SendOtpResponse> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registersendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200) {
      return SendOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse(ApiUrls.registerverifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    if (response.statusCode == 200) {
      return VerifyOtpResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('OTP verification failed');
    }
  }

  Future<CompleteRegistrationResponse> completeRegistration({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse(ApiUrls.completeRegistrationPartner),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "role": role,
      }),
    );
    if (response.statusCode == 200) {
      return CompleteRegistrationResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<RejectPartnerResponse> rejectPartner(int partnerId, String reason) async {
    final response = await http.post(
      Uri.parse(ApiUrls.rejectPartner),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"partner_id": partnerId, "reason": reason}),
    );
    if (response.statusCode == 200) {
      return RejectPartnerResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Reject failed');
    }
  }
}
//===========================referred_companies_service===============
class ReferredCompaniesService {
  Future<ReferredCompaniesResponse> fetchReferredCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.marketingHeadCompanies),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ReferredCompaniesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load referred companies: ${response.statusCode}');
    }
  }
}
//=============================================================================================================
//-------------------------------------------------marketing partner------------------------------------------
//=========================================================================================================
class MyReferredCompaniesService {
  Future<MyReferredCompaniesResponse> fetchMyCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.myMarketingCompanies),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MyReferredCompaniesResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load my referred companies: ${response.statusCode}');
    }
  }
}
// ============================= Agreement ===================================
class AgreementService {
  Future<Map<String, dynamic>> createPartnerHeadAgreement({
    required String agreementStartDate,
    required String agreementEndDate,
    required String companyOwnerName,
    required String companyAddress,
    required String ownerAdharNumber,
    required String ownerPanNumber,
    required double profitSharePercentage,
    required String additionalPoints,
    required String remarks,
    required XFile headSignatureImage,
    required XFile headPictureImage,
    XFile? agreementPdfFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiUrls.createPartnerHeadAgreement),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['agreement_start_date'] = agreementStartDate;
    request.fields['agreement_end_date'] = agreementEndDate;
    request.fields['company_owner_name'] = companyOwnerName;
    request.fields['company_address'] = companyAddress;
    request.fields['owner_adhar_number'] = ownerAdharNumber;
    request.fields['owner_pan_number'] = ownerPanNumber;
    request.fields['profit_share_percentage'] = profitSharePercentage.toString();
    request.fields['additional_points'] = additionalPoints;
    request.fields['remarks'] = remarks;

    await _addFile(request, headSignatureImage, 'companySign');
    await _addFile(request, headPictureImage, 'companyPicture');

    if (agreementPdfFile != null) {
      await _addFile(request, agreementPdfFile, 'uploadedAgreementPdf');
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to create agreement: $responseBody');
    }
  }

  Future<Map<String, dynamic>> fetchMarketingPartnerAgreement(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.marketingPartnerAgreement),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "marketing_partner_id": partnerId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch partner agreement: ${response.body}');
    }
  }

  Future<void> _addFile(http.MultipartRequest request, XFile file, String fieldName) async {
    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(file.name);
    final String primaryType = mimeType == 'pdf' ? 'application' : 'image';

    final multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: MediaType(primaryType, mimeType),
    );
    request.files.add(multipartFile);
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    if (lower.endsWith('.pdf')) return 'pdf';
    return 'jpeg';
  }
}
// ---------------------------------create bank detail---------------------------------
class CreateBankDetailsRequest {
  Future<BankDetailsResponse> createBankDetails(BankDetailsRequest requestData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    final response = await http.post(
      Uri.parse(ApiUrls.createBankDetails),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(requestData.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BankDetailsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }
}
// ---------------------------------Retrieve bank detail---------------------------------
// lib/api/marketing_service.dart

class RetrieveBankDetailsService {
  final http.Client _client;

  RetrieveBankDetailsService({http.Client? client})
      : _client = client ?? http.Client();

  /// ✅ Retrieve bank details for a specific marketing partner
  Future<RetrieveBankDetailsResponse> retrieveBankDetails(
      RetrieveBankDetailsRequest request
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      print('📤 Retrieve Bank Details');
      print('URL: ${ApiUrls.retrieveBankDetails}');
      print('📤 Request Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.retrieveBankDetails),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return RetrieveBankDetailsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to retrieve bank details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Retrieve Bank Details Error: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
// ============================= Marketing Agreement Service ===================================
class MarketingAgreementService {
  Future<Map<String, dynamic>> createPartnerHeadAgreement({
    required String agreementStartDate,
    required String agreementEndDate,
    required String companyOwnerName,
    required String companyAddress,
    required String ownerAdharNumber,
    required String ownerPanNumber,
    required double profitSharePercentage,
    required String additionalPoints,
    required String remarks,
    required XFile headSignatureImage,
    required XFile headPictureImage,
    XFile? agreementPdfFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiUrls.createPartnerHeadAgreement),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['agreement_start_date'] = agreementStartDate;
    request.fields['agreement_end_date'] = agreementEndDate;
    request.fields['company_owner_name'] = companyOwnerName;
    request.fields['company_address'] = companyAddress;
    request.fields['owner_adhar_number'] = ownerAdharNumber;
    request.fields['owner_pan_number'] = ownerPanNumber;
    request.fields['profit_share_percentage'] = profitSharePercentage.toString();
    request.fields['additional_points'] = additionalPoints;
    request.fields['remarks'] = remarks;

    await _addFile(request, headSignatureImage, 'companySign');
    await _addFile(request, headPictureImage, 'companyPicture');

    if (agreementPdfFile != null) {
      await _addFile(request, agreementPdfFile, 'uploadedAgreementPdf');
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to create agreement: $responseBody');
    }
  }

  Future<Map<String, dynamic>> fetchMarketingPartnerAgreement(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('No access token found. Please login again.');
    }

    final response = await http.post(
      Uri.parse(ApiUrls.marketingPartnerAgreement),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "marketing_partner_id": partnerId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch partner agreement: ${response.body}');
    }
  }

  Future<void> _addFile(http.MultipartRequest request, XFile file, String fieldName) async {
    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(file.name);
    final String primaryType = mimeType == 'pdf' ? 'application' : 'image';

    final multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: MediaType(primaryType, mimeType),
    );
    request.files.add(multipartFile);
  }

  String _getMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    if (lower.endsWith('.pdf')) return 'pdf';
    return 'jpeg';
  }
}
// ===============marketing head bank detail service =====================================================
class BankDetailsService {
  final http.Client _client;

  BankDetailsService({http.Client? client}) : _client = client ?? http.Client();

  Future<BankDetailsResponse> createBankDetails(BankDetailsRequest request) async {
    try {
      // ✅ Validate request first
      final validationError = _validateRequest(request);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // ✅ Get actual partner ID
      final partnerId = await _getActualPartnerId();
      if (partnerId != request.marketingPartner) {
        print('⚠️ Using actual partner ID: $partnerId instead of ${request.marketingPartner}');
        request = BankDetailsRequest(
          marketingPartner: partnerId,
          accountHolderName: request.accountHolderName,
          bankName: request.bankName,
          branchName: request.branchName,
          accountNumber: request.accountNumber,
          ifscCode: request.ifscCode,
          accountType: request.accountType,
          upiId: request.upiId,
        );
      }

      final response = await _client.post(
        Uri.parse(ApiUrls.createBankDetails),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📤 Request: ${jsonEncode(request.toJson())}');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BankDetailsResponse.fromJson(jsonDecode(response.body));
      } else {
        // ✅ Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Unknown error';

        // ✅ Handle field-specific errors
        if (errorData.containsKey('errors')) {
          final errors = errorData['errors'] as Map;
          errorMessage = errors.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Bank Details Error: $e');
      rethrow;
    }
  }

  String? _validateRequest(BankDetailsRequest request) {
    if (request.marketingPartner <= 0) {
      return 'Invalid marketing partner ID';
    }
    if (request.accountHolderName.trim().isEmpty) {
      return 'Account holder name is required';
    }
    if (request.bankName.trim().isEmpty) {
      return 'Bank name is required';
    }
    if (request.branchName.trim().isEmpty) {
      return 'Branch name is required';
    }
    if (request.accountNumber.trim().length < 9) {
      return 'Account number must be at least 9 digits';
    }
    if (request.ifscCode.trim().length != 11) {
      return 'IFSC code must be exactly 11 characters';
    }
    if (request.accountType.trim().isEmpty) {
      return 'Account type is required';
    }
    return null;
  }

  Future<int> _getActualPartnerId() async {
    final prefs = await SharedPreferences.getInstance();
    String? partnerId = prefs.getString('marketing_partner_id');

    if (partnerId == null || partnerId.isEmpty) {
      // Fetch from profile
      final profileService = MarketingProfileService();
      final response = await profileService.getMyProfile();
      if (response.status && response.data != null) {
        partnerId = response.data!.id.toString();
        await prefs.setString('marketing_partner_id', partnerId);
        return response.data!.id;
      }
      throw Exception('Could not find marketing partner ID');
    }
    return int.parse(partnerId);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }
    return token;
  }
}
// ============================================================
// PRODUCT REFERRAL SERVICE - COMPLETE
// ============================================================
// lib/services/marketing_profile_service.dart (मध्ये ProductReferralService)
class ProductReferralService {
  final http.Client _client;

  ProductReferralService({http.Client? client}) : _client = client ?? http.Client();

  /// Get approved products list
  Future<ApprovedProductListResponse> getApprovedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final response = await _client.post(
        Uri.parse(ApiUrls.approvedProductList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print('📤 Get Approved Products');
      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ApprovedProductListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Product List Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Generate referral link for a product
  Future<ProductReferralResponse> generateReferralLink({
    required int productId,
    required String referralCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // ✅ Request body as per your API
      final requestBody = {
        'product_id': productId,
        'referral_code': referralCode,
      };

      print('📤 Generate Referral Link');
      print('URL: ${ApiUrls.productReferral}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.productReferral),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return ProductReferralResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to generate referral link: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Product Referral Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}

//----------------commission_service-----------------------------------------

// lib/api/marketing_service.dart (CommissionService)

// lib/api/marketing_service.dart
// CommissionService class मध्ये हा change करा

class CommissionService {
  final http.Client _client;

  CommissionService({http.Client? client}) : _client = client ?? http.Client();

  Future<CommissionResponse> getCommission() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        // ✅ हे return करा, throw नको
        return CommissionResponse(
          status: false,
          message: 'No access token found. Please login again.',
          data: [],
        );
      }

      // ✅ Profile वरून actual marketing_partner_id मिळवा
      String partnerId = prefs.getString('marketing_partner_id') ?? '';

      // ✅ जर marketing_partner_id नसेल किंवा user_id सारखा असेल तर profile वरून मिळवा
      if (partnerId.isEmpty || partnerId == prefs.getString('user_id')) {
        try {
          final profileService = MarketingProfileService();
          final profileResponse = await profileService.getMyProfile();

          if (profileResponse.status && profileResponse.data != null) {
            partnerId = profileResponse.data!.id.toString();
            // ✅ Store for future use
            await prefs.setString('marketing_partner_id', partnerId);
            await prefs.setString('partner_id', partnerId);
            print('✅ Got marketing_partner_id from profile: $partnerId');
          }
        } catch (e) {
          print('❌ Could not get profile: $e');
          partnerId = prefs.getString('user_id') ?? '';
        }
      }

      if (partnerId.isEmpty) {
        return CommissionResponse(
          status: false,
          message: 'No partner ID found. Please login again.',
          data: [],
        );
      }

      if (!RegExp(r'^\d+$').hasMatch(partnerId)) {
        return CommissionResponse(
          status: false,
          message: 'Invalid partner ID format: $partnerId',
          data: [],
        );
      }

      print('✅ Using Partner ID: $partnerId');

      final response = await _client.post(
        Uri.parse(ApiUrls.commissionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'marketing_partner_id': partnerId,
        }),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return CommissionResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // ✅ 404 = No commission found
        return CommissionResponse(
          status: true,
          message: 'No commission records found',
          data: [],
        );
      } else {
        return CommissionResponse(
          status: false,
          message: 'Failed to fetch commission: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      print('❌ Commission Error: $e');
      return CommissionResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        data: [],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
//=============================wallet_service===========================================



// lib/api/marketing_service.dart (किंवा lib/services/marketing_profile_service.dart)

class WalletService {
  final http.Client _client;

  WalletService({http.Client? client}) : _client = client ?? http.Client();

  /// ✅ Get wallet balance
  Future<WalletResponse> getWalletBalance(int marketingPartnerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return WalletResponse(
          status: false,
          message: 'No access token found. Please login again.',
          data: null,
        );
      }

      final requestBody = {
        'marketing_partner_id': marketingPartnerId.toString(),
      };

      print('📤 Get Wallet Balance');
      print('URL: ${ApiUrls.walletUrl}'); // You need to add this URL
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.walletUrl), // ✅ हा URL add करा
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return WalletResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return WalletResponse(
          status: false,
          message: 'Wallet not found',
          data: null,
        );
      } else {
        return WalletResponse(
          status: false,
          message: 'Failed to fetch wallet: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      print('❌ Wallet Error: $e');
      return WalletResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Submit withdraw request
  Future<WithdrawResponse> submitWithdrawRequest(int marketingPartnerId, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final requestBody = {
        'marketing_partner_id': marketingPartnerId,
        'amount': amount,
      };

      print('📤 Submit Withdraw Request');
      print('URL: ${ApiUrls.walletWithdrawUrl}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.walletWithdrawUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return WithdrawResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to submit withdraw request: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Withdraw Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}

// lib/services/marketing_partner_service.dart




class MarketingPartnerService {
  final http.Client _client;

  MarketingPartnerService({http.Client? client})
      : _client = client ?? http.Client();

  /// ✅ Get all marketing partners with commission
  Future<PartnerCommissionListResponse> getPartnersWithCommission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return PartnerCommissionListResponse(
          status: false,
          message: 'No access token found. Please login again.',
          count: 0,
          data: [],
        );
      }

      print('📤 Get Partners with Commission');
      print('URL: ${ApiUrls.marketingPartnerCommissionList}');

      final response = await _client.post(
        Uri.parse(ApiUrls.marketingPartnerCommissionList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}), // Empty body as per API
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PartnerCommissionListResponse.fromJson(jsonData);
      } else {
        return PartnerCommissionListResponse(
          status: false,
          message: 'Failed to fetch partners: ${response.statusCode}',
          count: 0,
          data: [],
        );
      }
    } catch (e) {
      print('❌ Get Partners Error: $e');
      return PartnerCommissionListResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        count: 0,
        data: [],
      );
    }
  }

  /// ✅ Get wallet details for a specific partner
  Future<WalletResponse> getPartnerWallet(int marketingPartnerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        return WalletResponse(
          status: false,
          message: 'No access token found. Please login again.',
          data: null,
        );
      }

      final requestBody = {
        'marketing_partner_id': marketingPartnerId.toString(),
      };

      print('📤 Get Partner Wallet');
      print('URL: ${ApiUrls.marketingPartnerWallet}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.marketingPartnerWallet),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return WalletResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return WalletResponse(
          status: false,
          message: 'Wallet not found for this partner',
          data: null,
        );
      } else {
        return WalletResponse(
          status: false,
          message: 'Failed to fetch wallet: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      print('❌ Get Wallet Error: $e');
      return WalletResponse(
        status: false,
        message: 'Error: ${e.toString()}',
        data: null,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

//==========================pending commission=======================================================
class PendingCommissionService {
  final http.Client _client;

  PendingCommissionService({http.Client? client})
      : _client = client ?? http.Client();

  Future<PendingCommissionResponse> getPendingCommissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

// Get marketing partner ID from SharedPreferences
      String partnerId = prefs.getString('marketing_partner_id') ?? '';

// If not found, try to get from user_id
      if (partnerId.isEmpty) {
        partnerId = prefs.getString('user_id') ?? '';
      }

      if (partnerId.isEmpty) {
        throw Exception('No partner ID found. Please login again.');
      }

      final requestBody = {
        'marketing_partner_id': partnerId,
      };

      print('📤 Get Pending Commissions');
      print('URL: ${ApiUrls.pendingCommissionUrl}');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.pendingCommissionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PendingCommissionResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch pending commissions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Pending Commission Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}


// ✅ ============================================================
// ✅ FRANCHISE REFERRAL SERVICE - UPDATED
// ✅ ============================================================
class FranchiseReferralService {
  final http.Client _client;
  static const int defaultTimeout = 60;

  FranchiseReferralService({http.Client? client})
      : _client = client ?? http.Client();

  /// ✅ Get all franchises for referral
  Future<List<FranchiseListModel>> getFranchisesForReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔵 ===== GET FRANCHISES START =====');
      print('🔵 URL: ${ApiUrls.franchiseList}');
      print('🔵 Token exists: ${token != null}');

      final response = await _client.post(
        Uri.parse(ApiUrls.franchiseList),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: defaultTimeout));

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('🔵 Status: ${jsonData['status']}');
        print('🔵 Total: ${jsonData['total']}');

        final List<dynamic> data = jsonData['data'] ?? [];
        print('🔵 Data length: ${data.length}');

        return data.map((e) => FranchiseListModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load franchises: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Get Franchises Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// ✅ Generate referral link for a franchise - POST METHOD
  Future<FranchiseReferralResponse> generateReferralLink({
    required String product,
    required String referralCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final requestBody = {
        'product': product,
        'referral_code': referralCode,
      };

      print('🟢 ===== GENERATE REFERRAL LINK (POST) =====');
      print('🟢 URL: ${ApiUrls.generateFranchiseReferral}');
      print('🟢 Method: POST');
      print('🟢 Token exists: ${token != null}');
      print('🟢 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(ApiUrls.generateFranchiseReferral),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: defaultTimeout));

      print('🟢 Response Status: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('🟢 ✅ Referral link generated successfully!');
        return FranchiseReferralResponse.fromJson(jsonData);
      } else {
        print('🔴 Failed to generate referral link: ${response.statusCode}');
        print('🔴 Response: ${response.body}');
        throw Exception('Failed to generate referral link: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 Generate Referral Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}

//------------------update_bank_details_service------------------------------------------------


class UpdateBankDetailsService {
  final http.Client _client;

  UpdateBankDetailsService({http.Client? client})
      : _client = client ?? http.Client();

  /// Update bank details
  Future<UpdateBankDetailsResponse> updateBankDetails(
      UpdateBankDetailsRequest request
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      if (token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final url = Uri.parse(ApiUrls.updateBankDetails);
      final body = jsonEncode(request.toJson());

      print('📤 Update Bank Details URL: $url');
      print('📤 Request Body: $body');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return UpdateBankDetailsResponse.fromJson(jsonData);
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to update bank details');
      }
    } catch (e) {
      print('❌ Update Bank Details Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}



//------------------------------------------real_estate_service------------------------------------------------------


// lib/api/marketing_service.dart

class RealEstateService {
  final http.Client _client;

  RealEstateService({http.Client? client}) : _client = client ?? http.Client();

  /// Get approved properties
  Future<PropertyResponse> getApprovedProperties({
    int? agentId,
    String? referralCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final request = PropertyRequest(
        agentId: agentId,
        referralCode: referralCode,
        status: 'approved',
      );

      print('📤 Get Approved Properties');
      print('📤 URL: ${ApiUrls.approvedProperties}');
      print('📤 Request Body: ${jsonEncode(request.toJson())}');

      final response = await _client.post(
        Uri.parse(ApiUrls.approvedProperties),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return PropertyResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Properties Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}
// Add this class to marketing_service.dart



class RealEstateReferralService {
  final http.Client _client;

  RealEstateReferralService({http.Client? client})
      : _client = client ?? http.Client();

  /// Generate property referral link
  Future<PropertyReferralResponse> generateReferralLink(
      PropertyReferralRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      final url = Uri.parse(ApiUrls.propertyReferralGenerate);
      final requestBody = request.toJson();

      print('📤 ===== GENERATE PROPERTY REFERRAL LINK =====');
      print('📤 URL: $url');
      print('📤 Method: POST');
      print('📤 Token: ${token.substring(0, 10)}...');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);

        // ✅ Check if response has status field
        if (jsonData['status'] == true) {
          return PropertyReferralResponse.fromJson(jsonData);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to generate referral link');
        }
      } else {
        final jsonData = jsonDecode(response.body);
        throw Exception(jsonData['message'] ?? 'Failed to generate referral link');
      }
    } catch (e) {
      print('❌ Generate Property Referral Error: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  /// Get marketing partner's referral code from SharedPreferences
  static Future<String?> getReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final referralCode = prefs.getString('referral_code');
      print('🔍 Retrieved referral_code from SharedPreferences: $referralCode');
      return referralCode;
    } catch (e) {
      print('❌ Error getting referral code: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}